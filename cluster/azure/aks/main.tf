locals {
  msi_identity_type = "SystemAssigned"
}

module "azure-provider" {
  source = "../provider"
}

provider "azurerm" {
  subscription_id = var.subscription_id
}

resource "random_id" "workspace" {
  keepers = {
    group_name = var.log_analytics_resource_group_name
  }

  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "bedrock-k8s-workspace-${random_id.workspace.hex}"
  location            = var.log_analytics_resource_group_location
  resource_group_name = var.log_analytics_resource_group_name
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "solution" {
  solution_name         = "ContainerInsights"
  location              = var.log_analytics_resource_group_location
  resource_group_name   = var.log_analytics_resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  workspace_name        = azurerm_log_analytics_workspace.workspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  location            = var.aks_resource_group_location
  address_space       = [var.address_space]
  resource_group_name = var.aks_resource_group_name
  dns_servers         = []
  tags = {
    environment = "aks-vnet"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "aks-subnet"
  virtual_network_name = "aks-vnet"
  resource_group_name  = var.aks_resource_group_name
  address_prefix       = var.subnet_prefix
  service_endpoints    = []
  depends_on           = [azurerm_virtual_network.vnet]
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                            = var.cluster_name
  location                        = var.aks_resource_group_location
  resource_group_name             = var.aks_resource_group_name
  dns_prefix                      = var.dns_prefix
  kubernetes_version              = var.kubernetes_version
  node_resource_group             = var.node_resource_group
  api_server_authorized_ip_ranges = var.api_auth_ips

  linux_profile {
    admin_username = var.admin_user

    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  # The windows_profile block should be optional.  However, there is a bug in the Terraform Azure provider
  # that does not treat this block as optional -- even if no windows nodes are used.  If not present, any
  # change that should result in an update to the cluster causes a replacement.
  windows_profile {
    admin_username = "azureuser"
    admin_password = "FakePassword:Adm1nPa33++"
  }

  default_node_pool {
    name            = "default"
    node_count      = var.agent_vm_count
    vm_size         = var.agent_vm_size
    os_disk_size_gb = 30
    vnet_subnet_id  = azurerm_subnet.subnet.id
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_ip
    docker_bridge_cidr = var.docker_cidr
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      server_app_id     = var.server_app_id
      server_app_secret = var.server_app_secret
      client_app_id     = var.client_app_id
    }
  }

  dynamic "service_principal" {
    for_each = ! var.msi_enabled && var.service_principal_id != "" ? [{
      client_id     = var.service_principal_id
      client_secret = var.service_principal_secret
    }] : []
    content {
      client_id     = service_principal.value.client_id
      client_secret = service_principal.value.client_secret
    }
  }

  addon_profile {
    oms_agent {
      enabled                    = var.oms_agent_enabled
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }

    http_application_routing {
      enabled = var.enable_http_application_routing
    }

    kube_dashboard {
      enabled = true
    }

    azure_policy {
      enabled = true
    }
  }

  # This dynamic block enables managed service identity for the cluster
  # in the case that the following holds true:
  #   1: the msi_enabled input variable is set to true
  dynamic "identity" {
    for_each = var.msi_enabled ? [local.msi_identity_type] : []
    content {
      type = identity.value
    }
  }

  tags = var.tags

  depends_on = [azurerm_subnet.subnet]
}

data "external" "msi_object_id" {
  depends_on = [azurerm_kubernetes_cluster.cluster]
  program = [
    "${path.module}/aks_msi_client_id_query.sh",
    var.cluster_name,
    var.cluster_name,
    var.subscription_id
  ]
}
