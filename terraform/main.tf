terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }

  cloud {
    organization = "GiganticMinecraft"

    workspaces {
      name = "seichi_infra"
    }
  }
}

locals {
  # NOTE: account_idとzone_idは非シークレット
  # https://github.com/cloudflare/wrangler-legacy/issues/209#issuecomment-541654484
  cloudflare_account_id = "9e9e88e2b19878c4a911c3c8a715a168"
  cloudflare_zone_id    = "77c10fdfa7c65de4d14903ed8879ebcb"
  root_domain           = "seichi.click"
  github_org_name       = "GiganticMinecraft"
}

#region cloudflare provider

variable "cloudflare_email" {
  description = "email used for Cloudflare API authentication"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_key" {
  description = "API key used for Cloudflare API authentication"
  type        = string
  sensitive   = true
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

#endregion

#region cloudflare-github integration settings

variable "github_cloudflare_oauth_client_id" {
  description = "Client ID of Cloudflare as seens as an OAuth App on GitHub"
  type        = string
  sensitive   = true
}

variable "github_cloudflare_oauth_client_secret" {
  description = "Client secret of Cloudflare as seens as an OAuth App on GitHub"
  type        = string
  sensitive   = true
}

#endregion

#region terraform-github integration settings

variable "terraform_github_app_id" {
  description = "App ID of the GitHub App used for Terraform automation"
  type        = string
  sensitive   = true
}

# Found at
# https://github.com/organizations/GiganticMinecraft/settings/installations/:installation_id
variable "terraform_github_app_installation_id" {
  description = "Client installation ID of the GitHub App used for Terraform automation"
  type        = string
  sensitive   = true
}

variable "terraform_github_app_pem" {
  description = "Client private key of the GitHub App used for Terraform automation"
  type        = string
  sensitive   = true
}

provider "github" {
  owner = local.github_org_name
  app_auth {
    id              = var.terraform_github_app_id
    installation_id = var.terraform_github_app_installation_id
    pem_file        = var.terraform_github_app_pem
  }
}

#endregion

#region on-premise k8s access configuration

variable "onp_k8s_server_url" {
  description = "URL at which k8s server is exposed"
  type        = string
  sensitive   = true
}

variable "onp_k8s_kubeconfig" {
  description = "On-premise cluster's kubeconfig.yaml content"
  type        = string
  sensitive   = true
}

# オンプレクラスタの kubeconfig.yaml は、cluster CA certificate、client certificate、client keyをそれぞれ
#  - clusters[?].cluster.certificate-authority-data に
#  - users[?].user.client-certificate-data に
#  - users[?].user.client-key-data に
# base64で保持している。

locals {
  onp_kubernetes_cluster_ca_certificate = base64decode(yamldecode(var.onp_k8s_kubeconfig).clusters[0].cluster.certificate-authority-data)
  onp_kubernetes_client_certificate     = base64decode(yamldecode(var.onp_k8s_kubeconfig).users[0].user.client-certificate-data)
  onp_kubernetes_client_key             = base64decode(yamldecode(var.onp_k8s_kubeconfig).users[0].user.client-key-data)
}

provider "kubernetes" {
  host                   = var.onp_k8s_server_url
  cluster_ca_certificate = local.onp_kubernetes_cluster_ca_certificate
  client_certificate     = local.onp_kubernetes_client_certificate
  client_key             = local.onp_kubernetes_client_key
}

provider "helm" {
  kubernetes {
    host                   = var.onp_k8s_server_url
    cluster_ca_certificate = local.onp_kubernetes_cluster_ca_certificate
    client_certificate     = local.onp_kubernetes_client_certificate
    client_key             = local.onp_kubernetes_client_key
  }
}

#endregion

#region on-premise ArgoCD to GitHub integration

variable "onp_k8s_argocd_github_oauth_app_secret" {
  description = "The OAuth app secret for ArgoCD-GitHub integration on On-Premise Kubernetes cluster"
  type        = string
  sensitive   = true
}

variable "onp_k8s_argocd_applicationset_controller_github_app_id" {
  description = "App ID of the GitHub App used to avoid GitHub rate limit on the ApplicationSet Controller"
  type        = string
  sensitive   = true
}

# Found at
# https://github.com/organizations/GiganticMinecraft/settings/installations/:installation_id
variable "onp_k8s_argocd_applicationset_controller_github_app_installation_id" {
  description = "Client installation ID of the GitHub App used to avoid GitHub rate limit on the ApplicationSet Controller"
  type        = string
  sensitive   = true
}

variable "onp_k8s_argocd_applicationset_controller_github_app_pem" {
  description = "Client private key of the GitHub App used to avoid GitHub rate limit on the ApplicationSet Controller"
  type        = string
  sensitive   = true
}

variable "onp_k8s_argo_workflows_sso_client_secret" {
  description = "Client Secret of Argo Workflows SSO on ArgoCD dex"
  type        = string
  sensitive   = true
}

#endregion

#region on-premise Grafana to GitHub integration

variable "onp_k8s_grafana_github_oauth_app_id" {
  description = "The OAuth app id for Grafana-GitHub integration on On-Premise Kubernetes cluster"
  type        = string
  sensitive   = true
}

variable "onp_k8s_grafana_github_oauth_app_secret" {
  description = "The OAuth app secret for Grafana-GitHub integration on On-Premise Kubernetes cluster"
  type        = string
  sensitive   = true
}

#endregion

#region on-premise Synology CSI Driver Secret

variable "onp_k8s_synology_csi_config" {
  description = "Synology CSI Driver Token for On-Premise Kubernetes Cluster"
  type        = string
  sensitive   = true
}

#endregion

#region on-premise Cloudflared tunnel secret

# オンプレ k8s で走る cloudflared の認証情報。
# cloudflared login で得られる .pem ファイルの中身を設定してください。 
#
# 2022/06/01 現在、適切な権限を持った Cloduflare ユーザーが
# https://dash.cloudflare.com/argotunnel にアクセスして seichi-network を対象に認証することでも .pem が得られます。
variable "onp_k8s_cloudflared_tunnel_credential" {
  description = "Cloudflared tunnel credential for On-Premise Kubernetes Cluster"
  type        = string
  sensitive   = true
}

#endregion

#region on-premise MinIO

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}

variable "minio_prod_access_key" {
  description = "MinIO access key in production environment"
  type        = string
  sensitive   = true
}

variable "minio_prod_access_secret" {
  description = "MinIO access secret in production environment"
  type        = string
  sensitive   = true
}


variable "minio_debug_access_key" {
  description = "MinIO access key in debug environment"
  type        = string
  sensitive   = true
}

variable "minio_debug_access_secret" {
  description = "MinIO access secret in debug environment"
  type        = string
  sensitive   = true
}

#endregion

#region on-premise minecraft config secrets

variable "minecraft__discordsrv_bot_token" {
  description = "DiscordSRV bot token"
  type        = string
  sensitive   = true
}

variable "minecraft__prod_one_day_to_reset__morning_glory_seed_webhook_url" {
  description = "Webhook URL for MorningGlorySeeds on one-day-to-reset server in production env"
  type        = string
  sensitive   = true
}

variable "minecraft__prod_kagawa__morning_glory_seed_webhook_url" {
  description = "Webhook URL for MorningGlorySeeds on kagawa server in production env"
  type        = string
  sensitive   = true
}

variable "minecraft__prod_game_db__password" {
  description = "Password set to the production game database"
  type        = string
  sensitive   = true
}

#endregion

#region on-premise discord bot secrets

variable "discord_bot__idea_reaction__discord_token" {
  description = "Token set to the production idea-reaction"
  type        = string
  sensitive   = true
}

variable "discord_bot__idea_reaction__redmine_api_key" {
  description = "Redmine API Key set to the production idea-reaction"
  type        = string
  sensitive   = true
}

variable "discord_bot__babyrite__discord_token" {
  description = "Token set to the production babyrite"
  type        = string
  sensitive   = true
}

#endregion

#region env variables for Cloudflare Pages projects

variable "cloudflare_pages__seichi_portal__next_public_backend_api_url" {
  description = "The url of Seichi Portal backend API"
  type        = string
  sensitive   = true
}

variable "cloudflare_pages__seichi_portal__next_public_ms_app_client_id" {
  description = "The application cliend ID on Microsoft Azure Portal for Seichi Portal"
  type        = string
  sensitive   = true
}

#endregion

# region env variables for ArgoEvents

variable "argo_events_github_access_token" {
  description = "ArgoEvents GitHub access token"
  type        = string
  sensitive   = true
}

# endregion

# region env variables for proxmox-backup-client

variable "proxmox_backup_client__user" {
  description = "proxmox-backup-client user name"
  type        = string
  sensitive   = true
}

variable "proxmox_backup_client__host" {
  description = "proxmox-backup-client host"
  type        = string
  sensitive   = true
}

variable "proxmox_backup_client__datastore" {
  description = "proxmox-backup-client datastore"
  type        = string
  sensitive   = true
}

variable "proxmox_backup_client__password" {
  description = "proxmox-backup-client password"
  type        = string
  sensitive   = true
}

variable "proxmox_backup_client__fingerprint" {
  description = "proxmox-backup-client fingerprint at target server"
  type        = string
  sensitive   = true
}

# endregion
