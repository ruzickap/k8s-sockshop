resource "null_resource" "tekton" {

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${var.kubeconfig} -f https://github.com/tektoncd/pipeline/releases/download/${var.tekton_version}/release.yaml"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "exit 0"
  }
}

resource "null_resource" "tekton_dashboard" {
  depends_on = [null_resource.tekton]

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${var.kubeconfig} -f https://github.com/tektoncd/dashboard/releases/download/${var.tekton_dashboard_version}/release.yaml"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "kubectl delete --kubeconfig=${var.kubeconfig} -f https://github.com/tektoncd/dashboard/releases/download/${var.tekton_dashboard_version}/release.yaml"
  }
}

data "template_file" "tekton_dashboard-services" {
  template = file("${path.module}/files/tekton-services.yaml.tmpl")
  vars = {
    dnsName                 = var.dns_zone_name
    letsencrypt_environment = var.letsencrypt_environment
  }
}

resource "null_resource" "tekton_dashboard-services" {
  depends_on = [helm_release.istio, null_resource.cert-manager-certificate-label, null_resource.external-dns-sleep]

  triggers = {
    template_file_tekton_dashboard-services_sha1 = "${sha1("${data.template_file.tekton_dashboard-services.rendered}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${var.kubeconfig} -f -<<EOF\n${data.template_file.tekton_dashboard-services.rendered}\nEOF"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "kubectl delete --kubeconfig=${var.kubeconfig} -f -<<EOF\n${data.template_file.tekton_dashboard-services.rendered}\nEOF"
  }
}
