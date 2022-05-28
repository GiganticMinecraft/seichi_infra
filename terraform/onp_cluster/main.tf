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
