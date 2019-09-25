data "http" "flagger_crds" {
  url = "https://raw.githubusercontent.com/weaveworks/flagger/${var.flagger_version}/artifacts/flagger/crd.yaml"
}

resource "null_resource" "flagger_crds" {
  triggers = {
    template_file_flagger_crds_sha1 = "${sha1("${data.http.flagger_crds.body}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${var.kubeconfig} -f ${data.http.flagger_crds.url}"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "exit 0"
  }
}

data "helm_repository" "flagger" {
  name = "flagger"
  url  = "https://flagger.app"
}

resource "helm_release" "flagger" {
  depends_on = [null_resource.flagger_crds, kubernetes_cluster_role_binding.tiller]
  name       = "flagger"
  repository = "${data.helm_repository.flagger.metadata.0.name}"
  chart      = "flagger"
  version    = var.helm_flagger_version
  namespace  = kubernetes_namespace.istio-system.id

  set {
    name  = "crd.create"
    value = "false"
  }
  set {
    name  = "meshProvider"
    value = "istio"
  }
}

resource "helm_release" "flagger-grafana" {
  depends_on = [kubernetes_cluster_role_binding.tiller]
  name       = "flagger-grafana"
  repository = "${data.helm_repository.flagger.metadata.0.name}"
  chart      = "flagger/grafana"
  version    = var.helm_flagger-grafana_version
  namespace  = kubernetes_namespace.istio-system.id

  set {
    name  = "password"
    value = "admin"
  }
}

data "template_file" "flagger-grafana-services" {
  template = file("${path.module}/files/flagger-grafana-services.yaml.tmpl")
  vars = {
    dnsName                 = var.dns_zone_name
    letsencrypt_environment = var.letsencrypt_environment
  }
}

resource "null_resource" "flagger-grafana-services" {
  depends_on = [helm_release.istio, null_resource.cert-manager-certificate-label]

  triggers = {
    template_file_flagger-grafana_sha1 = "${sha1("${data.template_file.flagger-grafana-services.rendered}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${var.kubeconfig} -f -<<EOF\n${data.template_file.flagger-grafana-services.rendered}\nEOF"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "kubectl delete --kubeconfig=${var.kubeconfig} -f -<<EOF\n${data.template_file.flagger-grafana-services.rendered}\nEOF"
  }
}
