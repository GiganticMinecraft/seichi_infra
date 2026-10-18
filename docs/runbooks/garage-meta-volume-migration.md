# Garage meta ボリュームの storageClass 切り替え

## 概要

Garage の `meta` ボリューム (LMDB メタデータ) を Synology iSCSI (`synology-iscsi-storage`) から
ノードローカル NVMe (`topolvm-provisioner`) へ、ノード 1 台ずつ切り替える手順。
背景は #6364 を参照 (fsync 3ms 超で再同期が 40 時間ペース、iSCSI logout 起因の LMDB 破損)。

StatefulSet の `volumeClaimTemplates` は immutable で、Argo CD も `ignoreDifferences` で見ていない。
そのため `garage.yaml` の値を変えてマージしても既存の sts と PVC には何も起きず、以下を手で行う。

## 前提

- `replicationFactor: 2` なので、**未同期のノードが 2 台同時に存在してはいけない**。
  1 台を切り替えたら `garage worker list` で resync queue が 0 付近に戻り、全 sync ワーカーが Idle になるのを待ってから次へ進む。
- topolvm の PV はノードに固定される。切り替え後その Pod はそのノードから動けない。
  Pod は podAntiAffinity で 1 ノード 1 台なので、既に乗っているノードで作業する。
- LMDB が健全なら**空の PVC で再同期させず、ファイルをコピーして移す**。
  テーブル全件の再取得が不要になり、resync queue の中身もそのまま引き継がれる。
  10/3 と 10/15 のように LMDB が壊れている場合だけ、`node_key` 等の識別ファイルを退避して空の PVC から再同期させる。

## 手順 (garage-N を切り替える。N=0 の例)

### 0. マージと sts の作り直し (初回のみ)

```bash
# PR をマージ → Argo が sync しても live sts の vct は古いまま
kubectl -n garage delete sts garage --cascade=orphan   # Pod は残る
# Argo (selfHeal) が数秒で sts を再作成し、既存 Pod を adopt する
kubectl -n garage get sts garage -o jsonpath='{range .spec.volumeClaimTemplates[*]}{.metadata.name}={.spec.storageClassName}/{.spec.resources.requests.storage}{"\n"}{end}'
kubectl -n garage get sts garage -o jsonpath='{.status.currentRevision} {.status.updateRevision}{"\n"}'  # 両方が Pod の controller-revision-hash と一致すること (rolling update が始まらない)
```

### 1. 旧 PV を保全する

```bash
PV=$(kubectl -n garage get pvc meta-garage-0 -o jsonpath='{.spec.volumeName}')
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

### 2. ノードを cordon し、旧 PVC と Pod を消す

cordon するのは、sts が作り直す garage-0 Pod を Pending に留めるため (anti-affinity で他ノードには行けない)。
cordon 中はそのノード上の topolvm PV を持つ Pod (garage-backup-dump など) が再起動すると Pending になる。短時間で済ませる。

```bash
kubectl cordon seichi-onp-k8s-wk-1
kubectl -n garage delete pvc meta-garage-0 --wait=false     # Pod が使っているので Terminating で止まる
kubectl -n garage delete pod garage-0                        # 30s の猶予で Garage が LMDB を閉じる
kubectl -n garage get pvc meta-garage-0                      # 消えたことを確認 → sts が topolvm の meta-garage-0 を作り直す (Pending)
kubectl get pv "$PV" -o jsonpath='{.status.phase}{"\n"}'     # Released
```

### 3. 旧 PV を別名 PVC で再バインドし、ヘルパー Pod でコピーする

```bash
kubectl patch pv "$PV" --type json -p '[{"op":"replace","path":"/spec/claimRef","value":{"name":"meta-garage-0-old","namespace":"garage"}}]'
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: meta-garage-0-old
  namespace: garage
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: synology-iscsi-storage
  volumeName: <旧 PV 名>
  resources:
    requests:
      storage: 100Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: garage-0-meta-copy
  namespace: garage
spec:
  restartPolicy: Never
  nodeSelector:
    kubernetes.io/hostname: seichi-onp-k8s-wk-1
  tolerations:
    - key: node.kubernetes.io/unschedulable
      operator: Exists
      effect: NoSchedule
  containers:
    - name: copy
      image: busybox:stable
      command: ["sh", "-c", "set -e; df -h /src /dst; time cp -a /src/. /dst/; sync; chown -R 1000:1000 /dst; ls -la /dst; df -h /dst; echo COPY_DONE"]
      volumeMounts:
        - { name: src, mountPath: /src, readOnly: true }
        - { name: dst, mountPath: /dst }
  volumes:
    - name: src
      persistentVolumeClaim: { claimName: meta-garage-0-old, readOnly: true }
    - name: dst
      persistentVolumeClaim: { claimName: meta-garage-0 }   # ヘルパーが first consumer になり、このノードに LV が切られる
YAML
kubectl -n garage logs -f garage-0-meta-copy   # COPY_DONE を待つ
```

### 4. 復帰

```bash
kubectl -n garage delete pod garage-0-meta-copy
kubectl uncordon seichi-onp-k8s-wk-1            # garage-0 がスケジュールされ、コピーした LMDB で起動する
kubectl -n garage exec garage-0 -c garage -- /garage status   # ノード ID が以前と同じこと
kubectl -n garage exec garage-0 -c garage -- /garage worker list | head
```

### 5. 後片付け (数日様子を見てから)

```bash
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
kubectl -n garage delete pvc meta-garage-0-old   # Synology の LUN も消える
```

## ロールバック

手順 4 で起動しない場合: 再度 cordon → `garage-0` Pod と topolvm の `meta-garage-0` PVC を削除 →
旧 PV の claimRef を `meta-garage-0` に戻して同名 PVC を `volumeName` 指定で作る → uncordon。
旧 PV は Retain にしてあるので手順 5 を実行するまで中身は残っている。

## 関連

- #6364 (storageClass 変更), #6350 (metadata_fsync=true)
- `garage worker set resync-tranquility N` / `resync-worker-count N` で再同期速度を調整できる
  (2026-10-19 時点で garage-0 だけ tranquility 10、他は 2 だった)
