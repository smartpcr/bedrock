module "azure-provider" {
  source = "../provider"
}

provider "azurerm" {
  subscription_id = "${var.tm_subscription_id}"
}

resource "null_resource" "traffic_manager" {
  count = var.traffic_manager_name != "" && var.traffic_manager_name != "empty" && var.tm_resource_group_name != "" ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/create_traffic_manager.sh -s ${var.tm_subscription_id} -g ${var.tm_resource_group_name} -t ${var.traffic_manager_name} -e \"${var.service_names}\" -u \"${var.service_suffix}\" -z \"${var.dns_zone_name}\" -p \"${var.probe_path}\" -l \"${var.tm_location}\""
  }

  triggers = {
    traffic_manager_name   = "${var.traffic_manager_name}"
    tm_subscription_id     = "${var.tm_subscription_id}"
    tm_resource_group_name = "${var.tm_resource_group_name}"
    tm_location            = "${var.tm_location}"
    service_names          = "${var.service_names}"
    service_suffix         = "${var.service_suffix}"
    dns_zone_name          = "${var.dns_zone_name}"
    probe_path             = "${var.probe_path}"
  }
}

resource "null_resource" "cname_traffic_manager" {
  count = var.traffic_manager_name != "" && var.traffic_manager_name != "empty" && var.service_names != "" ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/add_trafficmanager_to_dns.sh -s ${var.dns_subscription_id} -g ${var.dns_resource_group_name} -z ${var.dns_zone_name} -t ${var.traffic_manager_name} -e \"${var.service_names}\""
  }

  triggers = {
    dns_zone_name           = "${var.dns_zone_name}"
    dns_subscription_id     = "${var.dns_subscription_id}"
    dns_resource_group_name = "${var.dns_resource_group_name}"
    traffic_manager_name    = "${var.traffic_manager_name}"
    service_names           = "${var.service_names}"
    recreate_cname_records  = "${var.recreate_cname_records}"
  }

  depends_on = ["null_resource.traffic_manager"]
}
