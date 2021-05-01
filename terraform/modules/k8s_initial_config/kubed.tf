data "helm_repository" "kubed" {
  name = "kubed"
  url  = "https://charts.appscode.com/stable/"
}

resource "helm_release" "kubed" {
  depends_on = [null_resource.cert-manager-certificate-label, kubernetes_cluster_role_binding.tiller]
  name       = "kubed"
  repository = data.helm_repository.kubed.metadata.0.name
  chart      = "kubed"
  version    = var.helm_kubed_version
  namespace  = "kubed"

  set {
    name  = "apiserver.enabled"
    value = "false"
  }
  set {
    name  = "config.clusterName"
    value = "${var.prefix}-${var.kubernetes_cluster_name}-${replace(var.dns_zone_name, ".", "-")}"
  }
}
