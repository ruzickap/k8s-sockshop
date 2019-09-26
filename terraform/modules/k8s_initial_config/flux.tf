resource "kubernetes_namespace" "flux" {
  metadata {
    name = "flux"
  }
}

resource "kubernetes_secret" "docker-config" {
  metadata {
    name      = "docker-config"
    namespace = kubernetes_namespace.flux.id
  }
  data = {
    "config.json" = "{\"auths\": {\"${var.prefix}${var.kubernetes_cluster_name}${replace(var.dns_zone_name, ".", "")}.azurecr.io\": {\"username\": \"${var.client_id}\", \"password\": \"${var.client_secret}\",\"auth\": \"${base64encode("${var.client_id}:${var.client_secret}")}\"}}}"
  }
  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "docker-config-default" {
  metadata {
    name      = "docker-config"
    namespace = "default"
  }
  data = {
    ".dockerconfigjson" = "{\"auths\": {\"${var.prefix}${var.kubernetes_cluster_name}${replace(var.dns_zone_name, ".", "")}.azurecr.io\": {\"username\": \"${var.client_id}\", \"password\": \"${var.client_secret}\",\"auth\": \"${base64encode("${var.client_id}:${var.client_secret}")}\"}}}"
  }
  type = "kubernetes.io/dockerconfigjson"
}

data "http" "flux" {
  url = "https://raw.githubusercontent.com/fluxcd/flux/helm-${var.flux_version}/deploy-helm/flux-helm-release-crd.yaml"
}

resource "null_resource" "flux_crds" {
  depends_on = [kubernetes_namespace.flux]
  triggers = {
    template_file_flux_sha1 = "${sha1("${data.http.flux.body}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${var.kubeconfig} -f ${data.http.flux.url}"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "exit 0"
  }
}

data "helm_repository" "flux" {
  name = "fluxcd"
  url  = "https://charts.fluxcd.io"
}

resource "helm_release" "flux" {
  depends_on = [null_resource.flux_crds, kubernetes_cluster_role_binding.tiller, kubernetes_secret.docker-config]
  name       = "flux"
  repository = "${data.helm_repository.flux.metadata.0.name}"
  chart      = "fluxcd/flux"
  version    = var.helm_flux_version
  namespace  = kubernetes_namespace.flux.id

  set {
    name  = "git.email"
    value = var.email
  }
  set {
    name  = "git.url"
    value = var.flux_git_url
  }
  set {
    name  = "git.user"
    value = "Flux"
  }
  set {
    name  = "helmOperator.create"
    value = "true"
  }
  set {
    name  = "helmOperator.createCRD"
    value = "false"
  }
  set {
    name  = "registry.dockercfg.configFileName"
    value = "/dockercfg/config.json"
  }
  set {
    name  = "registry.dockercfg.enabled"
    value = "true"
  }
  set {
    name  = "registry.dockercfg.secretName"
    value = "docker-config"
  }
  set {
    name  = "registry.pollInterval"
    value = "10s"
  }
  set {
    name  = "syncGarbageCollection.enabled"
    value = "true"
  }
}
