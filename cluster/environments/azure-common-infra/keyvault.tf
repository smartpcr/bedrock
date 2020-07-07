data "azurerm_client_config" "current" {}

module "keyvault" {
  source = "../../../cluster/azure/keyvault"

  vault_name       = "${var.vault_name}"
  resource_group_name = "${var.global_resource_group_name}"
  location            = "${var.global_resource_group_location}"
}

module "keyvault_access_policy_default" {
  source = "../../../cluster/azure/keyvault_policy"

  vault_id  = module.keyvault.keyvault_id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.service_principal_object_id
}

module "keyvault_access_policy_aks" {
  source = "../../../cluster/azure/keyvault_policy"

  vault_id           = module.keyvault.keyvault_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = var.service_principal_id
  key_permissions    = ["get"]
  secret_permissions = ["get"]

  # only aks policy if aks service principal separate from deployment service principal
  enabled            = var.service_principal_id == data.azurerm_client_config.current.service_principal_application_id ? false : true
}
