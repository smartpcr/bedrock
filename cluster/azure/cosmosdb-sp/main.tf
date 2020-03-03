resource "null_resource" "deploy_stored_procedures" {
  count = "${var.cosmos_db_settings != "" && var.cosmos_db_account != "" ? 1 : 0}"

  provisioner "local-exec" {
    command = "pwsh ${path.module}/ensure_cosmosdb_sp.ps1 -AccountName ${var.cosmos_db_account} -SubscriptionId ${var.cosmosdb_subscription_id} -DbSettings ${var.cosmos_db_settings} -VaultName ${var.vault_name}"
  }

  triggers = {
    cosmos_db_account        = "${var.cosmos_db_account}"
    cosmosdb_subscription_id = "${var.cosmosdb_subscription_id}"
    cosmosdb_created         = "${var.cosmosdb_created}"
    cosmos_db_settings        = "${var.cosmos_db_settings}"
  }
}
