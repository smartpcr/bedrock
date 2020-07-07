resource "local_file" "cluster_credentials_admin" {
  count = var.kubeconfig_to_disk ? 1 : 0
  sensitive_content = azurerm_kubernetes_cluster.cluster.kube_admin_config_raw
  filename          = "${var.output_directory}/${var.kubeconfigadmin_filename}"

  triggers = {
    kubeconfig_to_disk  = "${var.kubeconfig_to_disk}"
    kubeconfig_recreate = "${var.kubeconfig_recreate}"
  }

  depends_on = [azurerm_kubernetes_cluster.cluster]
}
