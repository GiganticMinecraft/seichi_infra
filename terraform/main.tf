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

variable "onp_k8s_kubeconfig" {
  description   = "On-premise cluster's kubeconfig.yaml content"
  type          = string
  sensitive     = true
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

# Terraform / Helm provider は、接続するためにトンネルを張る必要性があり複雑度が高いので、
# onp_cluster_providers.tf に記述している。

#endregion

#region on-premise ArgoCD to GitHub integration

variable "onp_k8s_argocd_github_oauth_app_secret" {
  description   = "The OAuth app secret for ArgoCD-GitHub integration on On-Premise Kubernetes cluster"
  type          = string
  sensitive     = true
}

#endregion

#region on-premise Grafana to GitHub integration

variable "onp_k8s_grafana_github_oauth_app_id" {
  description   = "The OAuth app id for Grafana-GitHub integration on On-Premise Kubernetes cluster"
  type          = string
  sensitive     = true
}

variable "onp_k8s_grafana_github_oauth_app_secret" {
  description   = "The OAuth app secret for Grafana-GitHub integration on On-Premise Kubernetes cluster"
  type          = string
  sensitive     = true
}

#endregion

#region on-premise Synology CSI Driver Secret

variable "onp_k8s_synology_csi_config" {
  description   = "Synology CSI Driver Token for On-Premise Kubernetes Cluster"
  type          = string
  sensitive     = true
}

#endregion
