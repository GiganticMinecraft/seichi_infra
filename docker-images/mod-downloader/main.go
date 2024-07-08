package main

import (
	"context"
	"log"
	"log/slog"
	"os"
	"strings"

	"github.com/getsentry/sentry-go"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

func init() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stderr, nil)))
}

func main() {
	err := sentry.Init(sentry.ClientOptions{
		Dsn: "https://4e29bb46d28a81476f9d565fb4e312a6@sentry.onp.admin.seichi.click//4",
		// Set TracesSampleRate to 1.0 to capture 100%
		// of transactions for performance monitoring.
		// We recommend adjusting this value in production,
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

	endpoint := os.Getenv("MINIO_ENDPOINT")
	accessKeyID := os.Getenv("MINIO_ACCESS_KEY")
	secretAccessKey := os.Getenv("MINIO_ACCESS_SECRET")
	useSSL := false

	// Initialize minio client object.
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		sentry.CaptureException(err)
		log.Fatalln(err)
		return
	}

	bucketName := os.Getenv("BUCKET_NAME")
	prefixName := os.Getenv("BUCKET_PREFIX_NAME")

	ctx, cancel := context.WithCancel(context.Background())

	defer cancel()

	objectCh := minioClient.ListObjects(ctx, bucketName, minio.ListObjectsOptions{
		Prefix:    prefixName,
		Recursive: true,
	})
	for object := range objectCh {
		if object.Err != nil {
			slog.Error("Error:", "error", object.Err)
			sentry.CaptureException(err)
			return
		}
		// キー名が最初からprefix付きで返ってくるので、ディレクトリ指定の際にはTrimする必要がある
		filePathToSave := downloadTargetDirPath + strings.TrimPrefix(object.Key, prefixName)
		slog.Info("Downloading object:", "objectKey", object.Key)
		err = minioClient.FGetObject(context.Background(), bucketName, object.Key, filePathToSave, minio.GetObjectOptions{})
		if err != nil {
			slog.Error("Error downloading object:", "objectKey", object.Key, "error", err)
			sentry.CaptureException(err)
			return
		}
		// 保存したファイルの所有権をitzg/minecraftに渡す ref. https://github.com/itzg/docker-minecraft-server/issues/1583
		err := os.Chown(filePathToSave, 1000, 1000)
		if err != nil {
			slog.Error("Error changing file ownership:", "filePath", filePathToSave, "error", err)
			sentry.CaptureException(err)
		} else {
			slog.Info("File ownership changed successfully", "filePath", filePathToSave)
		}
	}

	slog.Info("Downloaded all visible objects.")
}
