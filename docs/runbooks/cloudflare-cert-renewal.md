# Cloudflare証明書の更新

## 概要

Cloudflare経由で使用している証明書の更新手順。

## 証明書の種類

### 1. Edge証明書（Cloudflare管理）

Cloudflareが自動的に管理・更新するため、手動対応不要。

### 2. Origin証明書

Cloudflareダッシュボードから発行するOrigin証明書。
最大15年の有効期限を設定可能。

### 3. Cloudflare Tunnel用証明書

`cloudflared login`で取得する証明書。

## 手順

### Tunnel証明書の更新

1. 適切な権限を持つCloudflareユーザーでログイン

2. 証明書を取得
   ```bash
   cloudflared login
   ```

3. 取得した証明書（cert.pem）をTerraform Cloudのシークレットに更新
   - Variable: `TF_VAR_ONP_K8S_CLOUDFLARED_TUNNEL_CREDENTIAL`

4. Terraform applyを実行

## 関連リンク

- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [terraform/README.md](https://github.com/GiganticMinecraft/seichi_infra/blob/main/terraform/README.md)
