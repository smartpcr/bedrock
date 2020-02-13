output "client_certificate" {
  sensitive = true
  value     = "${azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate}"
}

output "kube_config" {
  sensitive = true
  value     = "${azurerm_kubernetes_cluster.cluster.kube_config_raw}"
}

output "kube_config_admin" {
  sensitive = true
  value = "${azurerm_kubernetes_cluster.cluster.kube_admin_config_raw}"
}

output "cluster_created" {
  value = "${join("",azurerm_kubernetes_cluster.cluster.*.id)}"
}

output "kubeconfig_done" {
  value = "${join("",null_resource.cluster_credentials.*.id)}"
}

output "kubeconfigadmin_done" {
  value = "${join("",null_resource.cluster_credentials_admin.*.id)}"
}
