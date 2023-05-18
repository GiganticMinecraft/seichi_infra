package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

func main() {
	downloadTargetDirPath := os.Getenv("DOWNLOAD_TARGET_DIR_PATH")
	err := os.MkdirAll(downloadTargetDirPath, 0600)

	if err != nil {
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
			fmt.Println(object.Err)
			return
		}
		fmt.Println("Downloading object:", object.Key)
		// キー名が最初からprefix付きで返ってくるので、ディレクトリ指定の際にはTrimする必要がある
		err = minioClient.FGetObject(context.Background(), bucketName, object.Key, downloadTargetDirPath+strings.TrimPrefix(object.Key, prefixName), minio.GetObjectOptions{})
		if err != nil {
			fmt.Println(err)
			return
		}
	}

	fmt.Println("Downloaded all visible objects.")
}
