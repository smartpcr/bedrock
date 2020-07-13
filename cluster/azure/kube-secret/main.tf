module "azure-provider" {
  source = "../provider"
}

provider "azurerm" {
  subscription_id = var.aks_subscription_id
}

resource "null_resource" "create_k8s_secret" {
  count = var.k8s_secret_name != "" && var.key_vault_name != "" && var.key_vault_secret_name != "" ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Need to use this var so terraform waits for kubeconfig ' ${var.kubeconfigadmin_done};KUBECONFIG=${var.output_directory}/${var.kubeconfigadmin_filename} ${path.module}/create_k8s_secret.sh -a ${var.aks_subscription_id} -b ${var.vault_subscription_id} -v ${var.key_vault_name} -s ${var.key_vault_secret_name} -n ${var.k8s_secret_name} -m \"${var.k8s_namespaces}\""
  }

  triggers = {
    aks_subscription_id      = var.aks_subscription_id
    k8s_secret_name          = var.k8s_secret_name
    vault_subscription_id    = var.vault_subscription_id
    key_vault_name           = var.key_vault_name
    key_vault_secret_name    = var.key_vault_secret_name
    k8s_namespaces           = var.k8s_namespaces
    key_vault_secret_version = var.key_vault_secret_version
  }
}
