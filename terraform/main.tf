terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  cloud {
    organization = "GiganticMinecraft"

    workspaces {
      name = "seichi_cloudflare_terraform"
    }
  }
}

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

locals {
  cloudflare_zone_id = "77c10fdfa7c65de4d14903ed8879ebcb"
  root_domain = "seichi.click"
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}
