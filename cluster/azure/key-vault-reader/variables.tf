variable "aks_subscription_id" {
  type = string
  description = "azure subscription id where aks/kv-reader is created"
}

variable "vault_subscription_id" {
  type = string
}

variable "resource_group_name" {
  description = "Default resource group name that the network will be created in."
}

variable "node_resource_group_name" {
  description = "resource group that contains default node pool for aks."
}

variable "location" {
  description = "The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  type        = string
}

variable "vault_name" {
  type        = string
  description = "Name of the keyvault to create"
}

variable "vault_reader_identity" {
  description = "name of user assigned identity (MSI) that will be granted reader role to key vault. The identity name must be by unique within subscription"
  type        = string
}

variable "aks_cluster_name" {
  type        = string
  description = "name of AKS cluster"
}

variable "aks_cluster_spn_object_id" {
  type        = string
  description = "object id of AKS cluster service principal"
}

variable "kubeconfigadmin_filename" {
  description = "Name of the admin kube config file saved to disk."
  type        = string
  default     = "admin_kube_config"
}

variable "kubeconfigadmin_done" {
  description = "Allows flux to wait for the admin kubeconfig completion write to disk. Workaround for the fact that modules themselves cannot have dependencies."
  type        = string
  default     = "true"
}

variable "output_directory" {
  type    = string
  default = "./output"
}
