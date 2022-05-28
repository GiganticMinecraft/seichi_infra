variable "cluster_host" {
  type          = string
  sensitive     = true
}

variable "cluster_ca_certificate" {
  type          = string
  sensitive     = true
}

variable "client_certificate" {
  type          = string
  sensitive     = true
}

variable "client_key" {
  type          = string
  sensitive     = true
}

provider "kubernetes" {
  host                   = var.cluster_host
  cluster_ca_certificate = var.cluster_ca_certificate
  client_certificate     = var.client_certificate
  client_key             = var.client_key
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_host
    cluster_ca_certificate = var.cluster_ca_certificate
    client_certificate     = var.client_certificate
    client_key             = var.client_key
  }
}
