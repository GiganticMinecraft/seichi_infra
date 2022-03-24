terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
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
  cloudflare_zone_id = "77c10fdfa7c65de4d14903ed8879ebcb"
  root_domain = "seichi.click"
  github_org_name = "GiganticMinecraft"
}

# region cloudflare provider

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

# endregion

# region cloudflare-github integration settings

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

# endregion

# region terraform-github integration settings

variable "terraform_github_app_id" {
  description = "Client ID of the GitHub App used for Terraform automation"
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

# endregion

# region proxy-layer's k8s access configuration

variable "lke_k8s_kubeconfig" {
  description   = "LKE cluster's kubeconfig.yaml content"
  type          = string
  sensitive     = true
}

# LKEの kubeconfig.yaml は、host、userのtokenとcluster CA certificateをそれぞれ
#  - clusters[?].cluster.server にplaintextで
#  - users[?].user.token にplaintextで
#  - clusters[?].cluster.certificate-authority-data にbase64で
# 保持している。
# LKE以外のmanaged k8s環境へ乗り換える際には、クラスタから得られるkubeconfigが含む情報が異なる可能性があるので注意。

provider "kubernetes" {
  host                   = yamldecode(var.lke_k8s_kubeconfig).clusters[0].cluster.server
  token                  = yamldecode(var.lke_k8s_kubeconfig).users[0].user.token
  cluster_ca_certificate = base64decode(yamldecode(var.lke_k8s_kubeconfig).clusters[0].cluster.certificate-authority-data)
}

# endregion

# region proxy-layer's ArgoCD to GitHub integration

variable "lke_k8s_argocd_github_oauth_app_secret" {
  description   = "The OAuth app secret for ArgoCD-GitHub integration on Kube cluster of proxy-layer"
  type          = string
  sensitive     = true
}

# endregion

# region proxy-layer's k8s cluster to Cloudflare integration

# プロキシ層の k8s で走る cloudflared の認証情報。
# cloudflared login で得られる .pem ファイルの中身を設定してください。 
variable "lke_k8s_cloudflare_argo_tunnel_credential" {
  description   = "The credential used by proxy-layer's cloudflared. This can be obtained using cloudflared login command."
  type          = string
  sensitive     = true
}

# endregion
