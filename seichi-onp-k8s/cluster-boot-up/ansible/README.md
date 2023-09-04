# ansible

## やっていること

 - cloud-initでセットアップされるホストはsshd_configのPasswordAuthenticationがtrueの状態
 - `seichi-onp-k8s-cp-1`をansibleサーバーとする
 - `seichi-onp-k8s-cp-1`で鍵ペアを生成して、`seichi-onp-k8s-cp-[2-3]`と`seichi-onp-k8s-wk-[1-3]`に配る
 - 鍵配ったらSSHのPasswordAuthenticationを塞ぐ
 - kubeadm joinとかをやる
