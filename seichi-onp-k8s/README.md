# seichi-onp-k8s

オンプレミスでデプロイされている整地鯖用のKubernetesクラスタを一元的に管理するディレクトリです。

クラスタ自体の構成情報、作成や削除に関する情報は [`cluster-boot-up`](./cluster-boot-up) を参照してください。

クラスタ内に置かれるリソースの設定は、 [`manifests/seichi-kubernetes`](./manifests/seichi-kubernetes) を参照してください。

クラスタ内に置かれるリソースは、[`manifests/seichi-kubernetes`](./manifests/seichi-kubernetes) で管理されるもの以外にも
 - クラスタ作成時に注入されるもの
 - [Terraform](../terraform/) により Secret 等として注入されるもの

等があることに注意してください。
