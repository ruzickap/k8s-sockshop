variable "accesskeyid" {
  default = "none"
}

variable "client_id" {
  default = "none"
}

variable "client_secret" {
  default = "none"
}

variable "cloud_platform" {
  default = "azure"
}

variable "dns_zone_name" {
  default = "myexample.dev"
}

variable "email" {
  default = "petr.ruzicka@gmail.com"
}

variable "flagger_version" {
  default = "0.18.4"
}

variable "flux_version" {
  description = "https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml"
  default     = "0.10.1"
}

variable "flux_git_url" {
  default = "git@github.com:ruzickap/k8s-flux-repository"
}

variable "kubernetes_cluster_name" {
  description = "Name for the Kubernetes cluster (will be used as part of the doman) [k8s.myexample.dev]"
  default     = "k8s"
}

variable "helm_cert-manager_version" {
  default = "v0.10.1"
}

variable "helm_external-dns_version" {
  default = "2.6.0"
}

variable "helm_flagger_version" {
  default = "0.18.4"
}

variable "helm_flux_version" {
  default = "0.14.1"
}

variable "helm_flagger-grafana_version" {
  default = "1.3.0"
}

variable "helm_istio_version" {
  default = "1.3.1"
}

variable "helm_kubed_version" {
  default = "v0.11.0"
}

variable "kubeconfig" {}

variable "letsencrypt_environment" {
  default = "staging"
}

variable "location" {
  default = "eu-central-1"
}

variable "prefix" {
  default = "mytest"
}

variable "resource_group_name" {
  default = "terraform_resource_group_name"
}

variable "resource_group_name_dns" {
  description = "Resource group where Terrafrom can locate DNS zone (myexample.dev)"
  default     = "terraform_resource_group_name-dns"
}

variable "secret_access_key" {
  default = "none"
}

variable "subscription_id" {
  default = "none"
}

variable "tekton_dashboard_version" {
  default = "v0.1.1"
}

variable "tekton_version" {
  default = "v0.7.0"
}

variable "tenant_id" {
  default = "none"
}
