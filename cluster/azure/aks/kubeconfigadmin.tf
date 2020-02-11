
resource "null_resource" "cluster_credentials_admin" {
  count = "${var.kubeconfig_to_disk ? 1 : 0}"

  provisioner "local-exec" {
    command = <<-EOT
      if [ ! -e ${var.output_directory} ]; then mkdir -p ${var.output_directory}; fi && \
      pwsh ${path.module}/write_kubeconfig.ps1 \
      -ClusterName ${var.cluster_name} \
      -ResourceGroupName ${var.aks_resource_group_name} \
      -KubeConfigFile "${var.output_directory}/${var.kubeconfigadmin_filename}" \
      -IsAdmin "true"
    EOT
  }

  triggers = {
    kubeconfig_to_disk  = "${var.kubeconfig_to_disk}"
    kubeconfig_recreate = "${var.kubeconfig_recreate}"
  }

  depends_on = ["azurerm_kubernetes_cluster.cluster"]
}
