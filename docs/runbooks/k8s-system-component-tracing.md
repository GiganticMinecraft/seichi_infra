# Kubernetesシステムコンポーネントのトレース

## 概要

kube-apiserver / etcd / kubelet / containerd が OpenTelemetry のトレースを出すように設定し、Tempo で見られるようにする手順。
いずれもホストのプロセス (または hostNetwork の静的 Pod) なので、各ノードの `127.0.0.1` で待ち受けるホスト受信用の Alloy に送る。

設定ファイルの実体は [`seichi-onp-k8s/cluster-boot-up/tracing/`](https://github.com/GiganticMinecraft/seichi_infra/tree/main/seichi-onp-k8s/cluster-boot-up/tracing) にある。

| ファイル | 置き場所 | 対象 |
| --- | --- | --- |
| `apiserver-tracing.yaml` | コントロールプレーンの `/etc/kubernetes/tracing/apiserver-tracing.yaml` | kube-apiserver |
| `containerd-otel.conf` | 全ノードの `/etc/systemd/system/containerd.service.d/10-otel.conf` | containerd |
| `kubeadm-config-tracing.snippet.yaml` | `kube-system/kubeadm-config` と `kube-system/kubelet-config` に追記する差分 | kube-apiserver / etcd / kubelet |

## 見えるもの

トレースは 2 系統できる。

1. **API リクエスト**: `apiserver` (受けた HTTP リクエスト) → `etcd` (gRPC の KV / Watch) と、admission webhook や aggregated API への呼び出し
2. **ノード上の Pod 操作**: `kubelet` (Pod 同期、CRI 呼び出し) → `containerd` (`RunPodSandbox` / `PullImage` / `CreateContainer` などの CRI サーバー側)

kube-scheduler / kube-controller-manager / CoreDNS は OTLP のトレースを出さないので、このトレースには出てこない。

| コンポーネント | service.name | サンプリング |
| --- | --- | --- |
| kube-apiserver | `apiserver` | 親のないリクエストの 1% (`samplingRatePerMillion: 10000`) |
| etcd | `etcd` | 自分では判定しない (`distributed-tracing-sampling-rate=0`)。apiserver でサンプリングされたリクエストだけ記録する |
| kubelet | `kubelet` | 親のない span の 1% (`samplingRatePerMillion: 10000`)。親があれば親に従う |
| containerd | `containerd` | `parentbased_traceidratio` / `0.01`。kubelet から来た CRI 呼び出しは kubelet の判定に従う |

## 前提条件

- ホスト受信用の Alloy DaemonSet (hostNetwork) が全ノードで動いており、`127.0.0.1:4317` (OTLP gRPC) と `127.0.0.1:4318` (OTLP HTTP) で待ち受けて Tempo に転送していること。
  リソース属性 `k8s.node.name` が無ければ Alloy が付ける。
  ```bash
  # 各ノードで
  ss -ltn | grep -E '127\.0\.0\.1:431[78]'
  ```
  受信側が止まっていても各コンポーネントは送信に失敗した span を捨てるだけで、本体の動作には影響しない。
- コントロールプレーン / ワーカーへの SSH と `sudo`
- リポジトリを手元に clone してあること (以下の `scp` はリポジトリのルートで実行する)

## 手順

containerd → kubelet → kube-apiserver → etcd の順に、**1 ノードずつ** 反映して確認してから次のノードに進む。
containerd を先にしておくと、kubelet を有効にした時点で kubelet → containerd のトレースがつながる。

### 0. 共有設定の準備 (最初に 1 回だけ)

#### 0-1. kube-apiserver の設定ファイルを全コントロールプレーンに置く

`kubeadm-config` の `apiServer.extraVolumes` は `pathType: File` でマウントするので、ファイルが無いノードで kubeadm がマニフェストを作り直すと kube-apiserver が起動しなくなる。
先に cp-1〜cp-3 のすべてに置いておく (置くだけなら何も変わらない)。

```bash
for n in seichi-onp-k8s-cp-1 seichi-onp-k8s-cp-2 seichi-onp-k8s-cp-3; do
  scp seichi-onp-k8s/cluster-boot-up/tracing/apiserver-tracing.yaml "$n":/tmp/
  ssh "$n" 'sudo install -d -m 0755 /etc/kubernetes/tracing \
    && sudo install -m 0600 -o root -g root /tmp/apiserver-tracing.yaml /etc/kubernetes/tracing/apiserver-tracing.yaml \
    && sudo ls -l /etc/kubernetes/tracing/'
done
```

#### 0-2. ConfigMap を更新する

`kubeadm-config-tracing.snippet.yaml` の内容を、既存のキーを残したまま各リストの末尾に追記する。

```bash
# 念のため退避
kubectl -n kube-system get cm kubeadm-config -o yaml > kubeadm-config.bak.yaml
kubectl -n kube-system get cm kubelet-config -o yaml > kubelet-config.bak.yaml

# data.ClusterConfiguration の apiServer.extraArgs / apiServer.extraVolumes / etcd.local.extraArgs に追記
kubectl -n kube-system edit cm kubeadm-config
# data.kubelet のトップレベルに tracing: を追記
kubectl -n kube-system edit cm kubelet-config
```

ConfigMap を書き換えただけでは、どのノードの設定も変わらない。各ノードには以降の手順で反映する。

追記後の設定は kubeadm で検証できる (読むだけで何も変えない)。

```bash
# 手元で
{ kubectl -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}'; echo '---';
  kubectl -n kube-system get cm kubelet-config -o jsonpath='{.data.kubelet}'; } \
  | ssh seichi-onp-k8s-cp-1 'kubeadm config validate --config /dev/stdin'
# => ok
```

### 1. containerd (全ノード、1 台ずつ)

```bash
# 手元で
scp seichi-onp-k8s/cluster-boot-up/tracing/containerd-otel.conf <node>:/tmp/
ssh <node>
```

```bash
# ノード上で
sudo install -d -m 0755 /etc/systemd/system/containerd.service.d
sudo install -m 0644 /tmp/containerd-otel.conf /etc/systemd/system/containerd.service.d/10-otel.conf
sudo systemctl daemon-reload
sudo systemctl restart containerd
systemctl is-active containerd
```

containerd の unit は `KillMode=process` なので、再起動しても shim と稼働中のコンテナは止まらない。
再起動の数秒間は kubelet が CRI のエラー (`connection refused` など) をログに出し、`kubectl logs -f` / `kubectl exec` の接続が切れることがある。

確認:

```bash
# 環境変数が containerd のプロセスに入っている
sudo cat /proc/$(pidof containerd)/environ | tr '\0' '\n' | grep '^OTEL_'

# tracing プラグインが読み込まれている
# "skip plugin: tracing endpoint not configured" が出ていたら環境変数が入っていない
sudo journalctl -u containerd --since '-5min' -o cat | grep -i tracing
sudo ctr plugins ls | grep -i tracing
# => io.containerd.tracing.processor.v1  otlp     -  ok
#    io.containerd.internal.v1           tracing  -  ok

kubectl get node <node>   # Ready のまま
```

cp-1 には `ExecStart` を差し替える `override.conf` が既にあるが、`10-otel.conf` は `Environment=` しか書かないので共存できる (`systemctl cat containerd` で両方が読まれていることを確認できる)。

この時点では kubelet がまだトレースを出していないので、containerd の span は親のない呼び出し (crictl など) の 1% しか出ない。

### 2. kubelet (全ノード、1 台ずつ)

0-2 で `kubelet-config` に `tracing:` を追記してあること。

```bash
# ノード上で
BAK=/root/kubelet-config.yaml.bak-$(date +%Y%m%d%H%M%S)
sudo cp /var/lib/kubelet/config.yaml "$BAK"
sudo kubeadm upgrade node phase kubelet-config
# tracing: が追加された以外に差分がないこと
sudo diff "$BAK" /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
systemctl is-active kubelet
kubectl get node <node>   # Ready に戻る
```

`kubeadm upgrade node phase kubelet-config` は `kubelet-config` ConfigMap をダウンロードして `/var/lib/kubelet/config.yaml` を上書きする (コントロールプレーンでは `/var/lib/kubelet/instance-config.yaml` のノード固有値も合成される)。
ノード上で `config.yaml` を直接書き換えても、次にこのコマンドや `kubeadm upgrade node` を実行したときに消えるので、正は ConfigMap にする。
kubelet の再起動では稼働中の Pod は再起動しない。

### 3. kube-apiserver (コントロールプレーン、1 台ずつ)

0-1 でファイルを置き、0-2 で `kubeadm-config` に `tracing-config-file` と `tracing-config` ボリュームを追記してあること。

#### 方法 A: kubeadm-config からマニフェストを作り直す (推奨)

```bash
# ノード上で
# 現在のマニフェストと kubeadm-config から作るマニフェストの差分を見る (何も変えない)
# --tracing-config-file と volumeMounts / volumes の tracing-config だけが出ること
# (upgrade diff が比べるのは kube-apiserver / kube-controller-manager / kube-scheduler だけで、etcd は対象外)
sudo kubeadm upgrade diff

# kube-apiserver / kube-controller-manager / kube-scheduler のマニフェストを作り直す。
# 差分がないコンポーネントは "Current and new manifests of ... are equal, skipping upgrade" で何もしない。
# --etcd-upgrade=false: etcd は手順 4 で扱う (true だと /var/lib/etcd を /etc/kubernetes/tmp に丸ごと複製する)
# --certificate-renewal=false: 証明書を更新しない (既定は true)
sudo kubeadm upgrade node phase control-plane --etcd-upgrade=false --certificate-renewal=false
```

kubeadm は古いマニフェストを `/etc/kubernetes/tmp/kubeadm-backed-up-manifests-*` に退避し、新しい kube-apiserver が起動するまで待つ。

#### 方法 B: マニフェストを手で直す

kubeadm を使えない場合 (`kubeadm upgrade diff` に想定外の差分が出るなど) は、`/etc/kubernetes/manifests/kube-apiserver.yaml` に次の 3 か所を足す。
**バックアップは `/etc/kubernetes/manifests/` の外に置く** (中に置くと kubelet が別の静的 Pod として起動しようとする)。

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/tmp/kube-apiserver.yaml.bak-$(date +%Y%m%d%H%M%S)
sudoedit /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    # ...既存の引数 (最後の --audit-log-maxsize=100 の後ろ)
    - --tracing-config-file=/etc/kubernetes/tracing/apiserver-tracing.yaml
    volumeMounts:
    # ...既存
    - mountPath: /etc/kubernetes/tracing/apiserver-tracing.yaml
      name: tracing-config
      readOnly: true
  volumes:
  # ...既存
  - hostPath:
      path: /etc/kubernetes/tracing/apiserver-tracing.yaml
      type: File
    name: tracing-config
```

保存すると kubelet が静的 Pod を作り直す。kubeadm-config にも同じ内容を書いてあれば、次の `kubeadm upgrade` でも消えない。

#### 確認

```bash
# 手元で (<node-ip> は cp-1: 192.168.32.11, cp-2: .12, cp-3: .13)
kubectl -n kube-system get pod kube-apiserver-<node> -o jsonpath='{.spec.containers[0].command}' | tr ',' '\n' | grep tracing
ssh <node> "sudo kubectl --kubeconfig /etc/kubernetes/admin.conf --server https://<node-ip>:6443 get --raw='/readyz'"
# => ok
kubectl -n kube-system get pod -l component=kube-apiserver -o wide   # 3 台とも Running / Ready
```

### 4. etcd (コントロールプレーン、1 台ずつ)

etcd のマニフェストは手で直す。
`kubeadm upgrade node phase control-plane` (`--etcd-upgrade=true`) でも作り直せるが、その場合は `/var/lib/etcd` を `/etc/kubernetes/tmp/kubeadm-backup-etcd-*` に丸ごと複製し、kube-apiserver の差分がある場合は etcd の再起動も伴う。
また kubeadm-config に etcd のイメージタグを書いていないため、kubeadm の既定バージョンと稼働中のイメージが違うと etcd のバージョンまで変わる。

**クォーラムを保つため、1 台の etcd が Ready に戻って健全性を確認できるまで次のノードに進まない。**

```bash
# ノード上で
sudo cp /etc/kubernetes/manifests/etcd.yaml /etc/kubernetes/tmp/etcd.yaml.bak-$(date +%Y%m%d%H%M%S)
sudo cp /etc/kubernetes/manifests/etcd.yaml /root/etcd.yaml.new
sudo sed -i 's#^    - --listen-metrics-urls=http://0.0.0.0:2381$#&\n    - --enable-distributed-tracing=true\n    - --distributed-tracing-address=127.0.0.1:4317\n    - --distributed-tracing-sampling-rate=0#' /root/etcd.yaml.new
# 3 行が増えただけであること (3 でなければ sed が当たっていないので止める)
sudo diff /etc/kubernetes/manifests/etcd.yaml /root/etcd.yaml.new
[ "$(sudo grep -cE -- '--(enable-distributed-tracing|distributed-tracing-address|distributed-tracing-sampling-rate)=' /root/etcd.yaml.new)" = 3 ] \
  && sudo cp /root/etcd.yaml.new /etc/kubernetes/manifests/etcd.yaml \
  || echo 'etcd.yaml.new にトレースの引数が 3 つ入っていない。マニフェストは変更していない' >&2
sudo rm /root/etcd.yaml.new
```

sed は `    - --listen-metrics-urls=http://0.0.0.0:2381` の行 (インデント 4) の直後に足す。このノードのマニフェストで形が違う場合は `sudoedit` で同じ 3 行を足す。
引数の並びは kubeadm が kubeadm-config から作るもの (既定の引数のあとに `extraArgs` を記載順に並べる) と揃えてある。

確認:

```bash
# 手元で
kubectl -n kube-system get pod etcd-<node> -o wide   # Running / Ready に戻るまで待つ
kubectl -n kube-system logs etcd-<node> | grep 'distributed tracing setup enabled'

kubectl -n kube-system exec etcd-<node> -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health --cluster
kubectl -n kube-system exec etcd-<node> -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --cluster -w table

# ノード上で (メトリクスは http://0.0.0.0:2381)
curl -s http://127.0.0.1:2381/metrics | grep -E '^etcd_server_(has_leader|is_leader|leader_changes_seen_total)'
# => etcd_server_has_leader 1
```

Prometheus では `etcd_server_has_leader` が全メンバーで 1 のままであること、`etcd_server_leader_changes_seen_total` が想定外に増えていないことを確認する。

#### (任意) メンバーごとの service.instance.id

`--distributed-tracing-instance-id` を指定しないと `service.instance.id` は付かない (空文字のときは属性自体を作らない)。
kubeadm-config はノード間で共有なのでノードごとの値は書けず、どのメンバーかは Alloy が付ける `k8s.node.name` で見分ける。
どうしても付けたい場合は、各ノードに kubeadm の patch (`/etc/kubernetes/patches/etcd+json.json` など) を置き、以後の `kubeadm upgrade apply` / `kubeadm upgrade node` に毎回 `--patches /etc/kubernetes/patches` を付ける必要がある。付け忘れると消えるので既定では使わない。

```json
[{"op": "add", "path": "/spec/containers/0/command/-", "value": "--distributed-tracing-instance-id=seichi-onp-k8s-cp-1"}]
```

### 5. Grafana (Tempo) での確認

Grafana の Explore で Tempo データソースを選び、TraceQL で検索する。

```traceql
// kube-apiserver の span
{ resource.service.name = "apiserver" }

// apiserver → etcd のつながり
{ resource.service.name = "apiserver" } >> { resource.service.name = "etcd" }

// etcd の span (apiserver でサンプリングされたリクエストの分だけ)
{ resource.service.name = "etcd" }

// kubelet の CRI 呼び出し (正規表現は全体一致なので前後に .* を付ける)
{ resource.service.name = "kubelet" && name =~ ".*(RunPodSandbox|PullImage|CreateContainer).*" }

// kubelet → containerd のつながり
{ resource.service.name = "kubelet" } >> { resource.service.name = "containerd" }

// k8s.node.name が付いていない span (0 件であること)
{ resource.service.name =~ "apiserver|etcd|kubelet|containerd" && resource.k8s.node.name = nil }

// ノードごとに見る
{ resource.service.name = "kubelet" && resource.k8s.node.name = "seichi-onp-k8s-wk-1" }
```

span が出てこない場合は、ノード上の受信側の Alloy を確認する。

```bash
# 受信側は monitoring namespace の DaemonSet alloy-host-receiver (Argo CD Application: alloy-host-receiver)
kubectl -n monitoring get pods -l app.kubernetes.io/name=alloy-host-receiver -o wide --field-selector spec.nodeName=<node>
kubectl -n monitoring logs ds/alloy-host-receiver --since=10m | grep -iE 'error|refused|otlp'
```

あわせて送信側も確認する。

- containerd: `journalctl -u containerd | grep -iE 'otlp|export'` (送信に失敗するとエクスポーターのエラーが出る)
- kubelet: `journalctl -u kubelet | grep -iE 'otlp|trac'`
- kube-apiserver / etcd: `kubectl -n kube-system logs <pod> | grep -iE 'otlp|trac'`

## ロールバック手順

いずれも 1 ノードずつ戻す。トレースを止めるだけなら、受信側の Alloy を止めても各コンポーネントは span を捨てるだけで動作に影響はない。

### containerd

```bash
sudo rm /etc/systemd/system/containerd.service.d/10-otel.conf
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo ctr plugins ls | grep -i tracing   # skip に戻る
```

### kubelet

```bash
# 手元で: data.kubelet から tracing: を消す
kubectl -n kube-system edit cm kubelet-config
# 各ノードで
sudo kubeadm upgrade node phase kubelet-config
sudo systemctl restart kubelet
```

### kube-apiserver

kubeadm-config から `tracing-config-file` と `tracing-config` ボリュームを消してから、各コントロールプレーンで次のどちらかを行う。

```bash
# kubeadm で作り直す
sudo kubeadm upgrade diff
sudo kubeadm upgrade node phase control-plane --etcd-upgrade=false --certificate-renewal=false

# または退避したマニフェストを戻す
# 方法 A で反映した場合 (kubeadm が退避したもの)
sudo cp /etc/kubernetes/tmp/kubeadm-backed-up-manifests-<日時>/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
# 方法 B で反映した場合 (手で退避したもの)
sudo cp /etc/kubernetes/tmp/kube-apiserver.yaml.bak-<日時> /etc/kubernetes/manifests/kube-apiserver.yaml
```

`/etc/kubernetes/tracing/apiserver-tracing.yaml` は残しておいても害はない。

### etcd

kubeadm-config の `etcd.local.extraArgs` から 3 つの引数を消してから、各コントロールプレーンで 1 台ずつ退避したマニフェストを戻し、手順 4 の確認を行う。

```bash
sudo cp /etc/kubernetes/tmp/etcd.yaml.bak-<日時> /etc/kubernetes/manifests/etcd.yaml
```

## 注意事項

- **kubeadm-config が正**: `kubeadm upgrade apply` / `kubeadm upgrade node` は静的 Pod のマニフェストを `kube-system/kubeadm-config` から作り直す。ノード上のマニフェストだけを直すと、次のアップグレードで消える。kubelet の設定も同様に `kube-system/kubelet-config` が正。
- **新しいコントロールプレーン**: kubeadm-config の `extraVolumes` が `pathType: File` なので、`kubeadm join --control-plane` の前に `/etc/kubernetes/tracing/apiserver-tracing.yaml` を置く (`k8s-node-setup.sh` は置くようになっている)。無いと kube-apiserver が起動しない。
- **kube-apiserver の feature gate**: `APIServerTracing` は 1.34 で GA、1.37 で feature gate ごと削除された。`--feature-gates=APIServerTracing=true` を付けると起動しないので付けない。kubelet の `tracing` も 1.34 で GA。
- **外部からの traceparent**: kube-apiserver が受け取った traceparent を親として引き継ぐのは、`system:masters` / `system:monitoring` グループのユーザーのリクエストだけ。それ以外は新しいトレースを始め、元のコンテキストはリンクとして残す。Argo CD などのクライアントのトレースと apiserver のトレースは基本的につながらない。
- **サンプリングのコスト**: Tempo は単一バイナリで、ローカルの 100Gi PVC に 720h 保持している。apiserver は常時数百 req/s を受けるため、比率を上げるとすぐにディスクが足りなくなる。上げるときは流入量 (`tempo_distributor_bytes_received_total` など) を見てから。readyz / livez などのヘルスチェックは受信側の Alloy で捨てている。
- **etcd のサンプリング率 0**: etcd 3.7 は `ParentBased(NeverSample)` になり、親が sampled の span (apiserver でサンプリングされたリクエスト) だけを記録する。0 より大きくすると apiserver を経由しない etcd 呼び出し (etcdctl やメンバー間の処理) の分も増える。
- **etcd のフラグ名**: etcd 3.7 では `--experimental-enable-distributed-tracing` などの `--experimental-*` 形式は削除されている。`--enable-distributed-tracing` などを使う。
- **containerd 1.x**: OTEL_* 環境変数でトレースが有効になるのは containerd 2.x から。1.7 以前は `config.toml` の `plugins."io.containerd.tracing.processor.v1.otlp"` などに書く必要があり、この drop-in だけでは span が出ない (`ctr plugins ls` で otlp が ok にならない)。
- **containerd の設定**: containerd 2.x のトレースは環境変数 (`OTEL_*`) だけで設定する。`config.toml` には書かない。`OTEL_EXPORTER_OTLP_ENDPOINT` には SDK が `/v1/traces` を付け足す。`OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` に切り替える場合は `http://127.0.0.1:4318/v1/traces` とパスまで書く。
- **node-runtime-updater**: containerd のバイナリを差し替える DaemonSet (`cluster-wide-apps/node-runtime-updater`) は systemd の drop-in を触らないので、更新後も `10-otel.conf` は残る。
- **トレースが出ないコンポーネント**:
  - kube-scheduler / kube-controller-manager は OTLP のトレースを実装していない。
  - CoreDNS の `trace` プラグインは Zipkin / Datadog 形式にしか対応しておらず、ここでは扱わない。

## 関連リンク

- [Traces For Kubernetes System Components](https://kubernetes.io/docs/concepts/cluster-administration/system-traces/)
- [TracingConfiguration (apiserver.config.k8s.io/v1)](https://kubernetes.io/docs/reference/config-api/apiserver-config.v1/#apiserver-k8s-io-v1-TracingConfiguration)
- [CHANGELOG-1.37 (APIServerTracing の feature gate 削除)](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.37.md)
- [kube-apiserver が traceparent を引き継ぐ条件 (filters/traces.go)](https://github.com/kubernetes/kubernetes/blob/release-1.37/staging/src/k8s.io/apiserver/pkg/endpoints/filters/traces.go)
- [etcd 3.7 のトレース設定 (server/embed/config_tracing.go)](https://github.com/etcd-io/etcd/blob/release-3.7/server/embed/config_tracing.go)
- [containerd tracing (release/2.4)](https://github.com/containerd/containerd/blob/release/2.4/docs/tracing.md)
- [containerd の OTLP プラグイン (pkg/tracing/plugin/otlp.go)](https://github.com/containerd/containerd/blob/release/2.4/pkg/tracing/plugin/otlp.go)
- [otlptracehttp の環境変数](https://pkg.go.dev/go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp)
- [kubeadm upgrade node phase](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-upgrade-phase/)
- [Kubernetesクラスターバージョンアップ](./k8s-cluster-upgrade.md)
