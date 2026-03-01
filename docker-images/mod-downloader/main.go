package main

import (
	"context"
	"log"
	"log/slog"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/feature/s3/transfermanager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/getsentry/sentry-go"
)

func init() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stderr, nil)))
}

func main() {
	err := sentry.Init(sentry.ClientOptions{
		Dsn:              "https://4e29bb46d28a81476f9d565fb4e312a6@sentry.onp.admin.seichi.click//4",
		TracesSampleRate: 1.0,
	})
	if err != nil {
		log.Fatalf("sentry.Init: %s", err)
	}

	downloadTargetDirPath := os.Getenv("DOWNLOAD_TARGET_DIR_PATH")
	err = os.MkdirAll(downloadTargetDirPath, 0600)
	if err != nil {
		sentry.CaptureException(err)
		log.Fatalln(err)
		return
	}

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

	cfg, err := config.LoadDefaultConfig(context.Background(),
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKeyID, secretAccessKey, "")),
	)
	if err != nil {
		sentry.CaptureException(err)
		log.Fatalln(err)
		return
	}

	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String("http://" + endpoint)
		o.UsePathStyle = true
	})

	bucketName := os.Getenv("BUCKET_NAME")
	prefixName := os.Getenv("BUCKET_PREFIX_NAME")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	tm := transfermanager.New(client)

	paginator := s3.NewListObjectsV2Paginator(client, &s3.ListObjectsV2Input{
		Bucket: aws.String(bucketName),
		Prefix: aws.String(prefixName),
	})

	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			slog.Error("Error listing objects:", "error", err)
			sentry.CaptureException(err)
			return
		}

		for _, object := range page.Contents {
			key := aws.ToString(object.Key)
			// キー名が最初からprefix付きで返ってくるので、ディレクトリ指定の際にはTrimする必要がある
			filePathToSave := downloadTargetDirPath + strings.TrimPrefix(key, prefixName)

			slog.Info("Downloading object:", "objectKey", key)

			// Ensure parent directory exists
			if dir := filePathToSave[:strings.LastIndex(filePathToSave, "/")]; dir != "" {
				if err := os.MkdirAll(dir, 0755); err != nil {
					slog.Error("Error creating directory:", "dir", dir, "error", err)
					sentry.CaptureException(err)
					return
				}
			}

			f, err := os.Create(filePathToSave)
			if err != nil {
				slog.Error("Error creating file:", "filePath", filePathToSave, "error", err)
				sentry.CaptureException(err)
				return
			}

			_, err = tm.DownloadObject(ctx, &transfermanager.DownloadObjectInput{
				Bucket:   aws.String(bucketName),
				Key:      aws.String(key),
				WriterAt: f,
			})
			if closeErr := f.Close(); closeErr != nil {
				slog.Error("Error closing file:", "filePath", filePathToSave, "error", closeErr)
			}
			if err != nil {
				slog.Error("Error downloading object:", "objectKey", key, "error", err)
				sentry.CaptureException(err)
				return
			}

			// 保存したファイルの所有権をitzg/minecraftに渡す ref. https://github.com/itzg/docker-minecraft-server/issues/1583
			if err := os.Chown(filePathToSave, 1000, 1000); err != nil {
				slog.Error("Error changing file ownership:", "filePath", filePathToSave, "error", err)
				sentry.CaptureException(err)
			} else {
				slog.Info("File ownership changed successfully", "filePath", filePathToSave)
			}
		}
	}

	slog.Info("Downloaded all visible objects.")
}
