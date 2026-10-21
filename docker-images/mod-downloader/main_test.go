package main

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/s3/transfermanager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

type fakeLister struct {
	keys []string
}

func (f *fakeLister) ListObjectsV2(ctx context.Context, in *s3.ListObjectsV2Input, _ ...func(*s3.Options)) (*s3.ListObjectsV2Output, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	out := &s3.ListObjectsV2Output{IsTruncated: aws.Bool(false)}
	for _, k := range f.keys {
		out.Contents = append(out.Contents, types.Object{Key: aws.String(k)})
	}
	return out, nil
}

type fakeDownloader struct {
	// block が true なら ctx が終わるまで返さない (応答しない Garage の代わり)
	block bool
}

func (f *fakeDownloader) DownloadObject(ctx context.Context, in *transfermanager.DownloadObjectInput, _ ...func(*transfermanager.Options)) (*transfermanager.DownloadObjectOutput, error) {
	if f.block {
		<-ctx.Done()
		return nil, ctx.Err()
	}
	if _, err := in.WriterAt.WriteAt([]byte(aws.ToString(in.Key)), 0); err != nil {
		return nil, err
	}
	return &transfermanager.DownloadObjectOutput{}, nil
}

func TestDownloadSuccess(t *testing.T) {
	dir := t.TempDir()
	lister := &fakeLister{keys: []string{"common-plugins/a.jar", "common-plugins/sub/b.yml"}}
	cfg := downloadConfig{bucket: "seichi-plugins", prefix: "common-plugins", targetDir: dir, minObjects: 1}

	n, err := download(context.Background(), lister, &fakeDownloader{}, cfg)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if n != 2 {
		t.Fatalf("want 2 objects, got %d", n)
	}
	got, err := os.ReadFile(filepath.Join(dir, "sub", "b.yml"))
	if err != nil {
		t.Fatalf("reading downloaded file: %v", err)
	}
	if string(got) != "common-plugins/sub/b.yml" {
		t.Fatalf("unexpected content: %q", got)
	}
}

func TestDownloadEmptyPrefixFails(t *testing.T) {
	cfg := downloadConfig{bucket: "seichi-plugins", prefix: "typo", targetDir: t.TempDir(), minObjects: 1}

	n, err := download(context.Background(), &fakeLister{}, &fakeDownloader{}, cfg)
	if err == nil {
		t.Fatal("want error for 0 objects, got nil")
	}
	if n != 0 {
		t.Fatalf("want 0 objects, got %d", n)
	}
}

func TestDownloadMinObjectsZeroAllowsEmpty(t *testing.T) {
	cfg := downloadConfig{bucket: "seichi-plugins", prefix: "typo", targetDir: t.TempDir(), minObjects: 0}

	if _, err := download(context.Background(), &fakeLister{}, &fakeDownloader{}, cfg); err != nil {
		t.Fatalf("unexpected error with MIN_OBJECTS=0: %v", err)
	}
}

func TestDownloadDeadlineExceeded(t *testing.T) {
	lister := &fakeLister{keys: []string{"master/SeichiAssist.jar"}}
	cfg := downloadConfig{bucket: "seichiassist", prefix: "master", targetDir: t.TempDir(), minObjects: 1}

	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()

	_, err := download(ctx, lister, &fakeDownloader{block: true}, cfg)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("want DeadlineExceeded, got %v", err)
	}
}

func TestEnvParsing(t *testing.T) {
	t.Setenv("DOWNLOAD_DEADLINE", "")
	if d, err := durationFromEnv("DOWNLOAD_DEADLINE", defaultDownloadDeadline); err != nil || d != defaultDownloadDeadline {
		t.Fatalf("default: got %v, %v", d, err)
	}
	t.Setenv("DOWNLOAD_DEADLINE", "45m")
	if d, err := durationFromEnv("DOWNLOAD_DEADLINE", defaultDownloadDeadline); err != nil || d != 45*time.Minute {
		t.Fatalf("45m: got %v, %v", d, err)
	}
	for _, v := range []string{"10", "0s", "-1m"} {
		t.Setenv("DOWNLOAD_DEADLINE", v)
		if _, err := durationFromEnv("DOWNLOAD_DEADLINE", defaultDownloadDeadline); err == nil {
			t.Fatalf("want error for %q", v)
		}
	}

	t.Setenv("MIN_OBJECTS", "")
	if n, err := minObjectsFromEnv("MIN_OBJECTS", defaultMinObjects); err != nil || n != 1 {
		t.Fatalf("default: got %v, %v", n, err)
	}
	t.Setenv("MIN_OBJECTS", "0")
	if n, err := minObjectsFromEnv("MIN_OBJECTS", defaultMinObjects); err != nil || n != 0 {
		t.Fatalf("0: got %v, %v", n, err)
	}
	for _, v := range []string{"-1", "x"} {
		t.Setenv("MIN_OBJECTS", v)
		if _, err := minObjectsFromEnv("MIN_OBJECTS", defaultMinObjects); err == nil {
			t.Fatalf("want error for %q", v)
		}
	}
}
