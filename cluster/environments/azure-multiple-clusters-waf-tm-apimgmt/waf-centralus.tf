module "central_waf_subnet" {
  source = "../../../cluster/azure/subnet"

  resource_group_name = data.azurerm_resource_group.centralrg.name
  vnet_name           = module.central_vnet.vnet_name
  subnet_name         = [ "${var.prefix}-centralwaf" ]
  address_prefix      = [ var.central_waf_address_prefix ]
}

module "central_waf" {
  source = "../../../cluster/azure/waf"

  resource_group_name     = data.azurerm_resource_group.centralrg.name
  wafname                 = "${var.prefix}-central-waf"
  subnet_id               = tostring(element(module.central_waf_subnet.subnet_ids, 0))
  public_ip_address_id    = module.central_tm_endpoint.public_ip_id
}
