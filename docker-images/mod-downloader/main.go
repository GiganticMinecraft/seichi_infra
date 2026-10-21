package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awshttp "github.com/aws/aws-sdk-go-v2/aws/transport/http"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/feature/s3/transfermanager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

const (
	// 全体の締め切り。Garage が応答しないまま init コンテナが止まり続けると、Pod は
	// Init のまま進まず、kubelet からは失敗にも見えないので誰も気付けない。
	// 締め切りを過ぎたら非 0 で終わらせて、kubelet にやり直させる
	defaultDownloadDeadline = 10 * time.Minute
	// ヘッダが返ってこないリクエストを打ち切るまでの時間。本文の転送が遅いだけの
	// 場合はここでは切らない (大きなオブジェクトは全体の締め切りで扱う)
	responseHeaderTimeout = 30 * time.Second
	// ダウンロードしたオブジェクト数の下限。prefix の打ち間違いやバケットの中身の消失で
	// 0 件になっても exit 0 で終わると、プラグイン無しで Minecraft サーバーが起動してしまう
	// (本体の startupProbe は 25565 番の tcpSocket だけなので検知できない)
	defaultMinObjects = 1
)

// objectDownloader は transfermanager.Client の DownloadObject だけを切り出したもの (テストで差し替えるため)
type objectDownloader interface {
	DownloadObject(ctx context.Context, input *transfermanager.DownloadObjectInput, opts ...func(*transfermanager.Options)) (*transfermanager.DownloadObjectOutput, error)
}

type downloadConfig struct {
	bucket     string
	prefix     string
	targetDir  string
	minObjects int
}

func init() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stderr, nil)))
}

func main() {
	os.Exit(run())
}

func run() int {
	deadline, err := durationFromEnv("DOWNLOAD_DEADLINE", defaultDownloadDeadline)
	if err != nil {
		slog.Error("Invalid DOWNLOAD_DEADLINE", "error", err)
		return 1
	}
	minObjects, err := minObjectsFromEnv("MIN_OBJECTS", defaultMinObjects)
	if err != nil {
		slog.Error("Invalid MIN_OBJECTS", "error", err)
		return 1
	}

	cfg := downloadConfig{
		bucket:     os.Getenv("BUCKET_NAME"),
		prefix:     os.Getenv("BUCKET_PREFIX_NAME"),
		targetDir:  os.Getenv("DOWNLOAD_TARGET_DIR_PATH"),
		minObjects: minObjects,
	}

	ctx, cancel := context.WithTimeout(context.Background(), deadline)
	defer cancel()

	client, err := newS3Client(ctx)
	if err != nil {
		slog.Error("Error creating S3 client", "error", err)
		return 1
	}

	count, err := download(ctx, client, transfermanager.New(client), cfg)
	if err != nil {
		// err 側で errors.Is(err, context.DeadlineExceeded) を見ると、net/http の
		// "timeout awaiting response headers" も一致してしまい全体の締め切りと区別できないので ctx 側で判定する
		if errors.Is(ctx.Err(), context.DeadlineExceeded) {
			slog.Error("Download deadline exceeded", "deadline", deadline.String(), "downloadedObjects", count, "error", err)
		} else {
			slog.Error("Download failed", "downloadedObjects", count, "error", err)
		}
		return 1
	}

	slog.Info("Downloaded all visible objects.", "downloadedObjects", count)
	return 0
}

func newS3Client(ctx context.Context) (*s3.Client, error) {
	endpoint := os.Getenv("S3_ENDPOINT")
	accessKeyID := os.Getenv("S3_ACCESS_KEY")
	secretAccessKey := os.Getenv("S3_SECRET_KEY")
	region := os.Getenv("S3_REGION")
	if region == "" {
		region = "seichi-cloud"
	}

	// Backward compatibility: fall back to MINIO_* env vars if S3_* are not set
	if endpoint == "" {
		endpoint = os.Getenv("MINIO_ENDPOINT")
	}
	if accessKeyID == "" {
		accessKeyID = os.Getenv("MINIO_ACCESS_KEY")
	}
	if secretAccessKey == "" {
		secretAccessKey = os.Getenv("MINIO_ACCESS_SECRET")
	}

	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKeyID, secretAccessKey, "")),
	)
	if err != nil {
		return nil, err
	}

	httpClient := awshttp.NewBuildableClient().WithTransportOptions(func(t *http.Transport) {
		t.ResponseHeaderTimeout = responseHeaderTimeout
	})

	return s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String("http://" + endpoint)
		o.UsePathStyle = true
		o.HTTPClient = httpClient
		// Garage はレスポンスに x-amz-checksum-* を付けないため、transfermanager の
		// 分割 GET ごとに「検証をスキップした」という DEBUG ログが出て数 GB で数百行になる。
		// 検証自体はチェックサムが返ってきた場合に効くよう残し、ログだけを止める
		o.DisableLogOutputChecksumValidationSkipped = true
	}), nil
}

// download は prefix 配下のオブジェクトを targetDir に保存し、保存したオブジェクト数を返す
func download(ctx context.Context, client s3.ListObjectsV2APIClient, tm objectDownloader, cfg downloadConfig) (int, error) {
	if err := os.MkdirAll(cfg.targetDir, 0600); err != nil {
		return 0, fmt.Errorf("creating target dir %q: %w", cfg.targetDir, err)
	}

	paginator := s3.NewListObjectsV2Paginator(client, &s3.ListObjectsV2Input{
		Bucket: aws.String(cfg.bucket),
		Prefix: aws.String(cfg.prefix),
	})

	count := 0
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			return count, fmt.Errorf("listing objects: %w", err)
		}

		for _, object := range page.Contents {
			key := aws.ToString(object.Key)
			if err := downloadObject(ctx, tm, cfg, key); err != nil {
				return count, err
			}
			count++
		}
	}

	if count < cfg.minObjects {
		return count, fmt.Errorf("downloaded %d objects from s3://%s/%s, fewer than MIN_OBJECTS=%d", count, cfg.bucket, cfg.prefix, cfg.minObjects)
	}
	return count, nil
}

func downloadObject(ctx context.Context, tm objectDownloader, cfg downloadConfig, key string) error {
	// キー名が最初からprefix付きで返ってくるので、ディレクトリ指定の際にはTrimする必要がある
	filePathToSave := cfg.targetDir + strings.TrimPrefix(key, cfg.prefix)

	slog.Info("Downloading object:", "objectKey", key)

	// Ensure parent directory exists
	if dir := filePathToSave[:strings.LastIndex(filePathToSave, "/")]; dir != "" {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("creating directory %q: %w", dir, err)
		}
	}

	f, err := os.Create(filePathToSave)
	if err != nil {
		return fmt.Errorf("creating file %q: %w", filePathToSave, err)
	}

	_, err = tm.DownloadObject(ctx, &transfermanager.DownloadObjectInput{
		Bucket:   aws.String(cfg.bucket),
		Key:      aws.String(key),
		WriterAt: f,
	})
	if closeErr := f.Close(); closeErr != nil {
		return fmt.Errorf("closing file %q: %w", filePathToSave, closeErr)
	}
	// 失敗時に exit 0 で終わると、途中までのファイルが emptyDir に残ったまま
	// 後続の init コンテナ (world-extractor 等) に進み、Pod を作り直すまで直らない。
	// 非 0 で終わらせて、init コンテナごとダウンロードからやり直させる
	if err != nil {
		return fmt.Errorf("downloading object %q: %w", key, err)
	}

	// 保存したファイルの所有権をitzg/minecraftに渡す ref. https://github.com/itzg/docker-minecraft-server/issues/1583
	if err := os.Chown(filePathToSave, 1000, 1000); err != nil {
		slog.Error("Error changing file ownership:", "filePath", filePathToSave, "error", err)
	} else {
		slog.Info("File ownership changed successfully", "filePath", filePathToSave)
	}
	return nil
}

func durationFromEnv(name string, def time.Duration) (time.Duration, error) {
	v := os.Getenv(name)
	if v == "" {
		return def, nil
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return 0, err
	}
	if d <= 0 {
		return 0, fmt.Errorf("%s must be positive, got %s", name, v)
	}
	return d, nil
}

func minObjectsFromEnv(name string, def int) (int, error) {
	v := os.Getenv(name)
	if v == "" {
		return def, nil
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return 0, err
	}
	if n < 0 {
		return 0, fmt.Errorf("%s must not be negative, got %s", name, v)
	}
	return n, nil
}
