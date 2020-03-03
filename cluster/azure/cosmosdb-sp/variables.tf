variable "cosmos_db_account" {
  type        = "string"
  description = "name of cosmosdb account"
}

variable "cosmosdb_subscription_id" {
  type    = "string"
  default = ""       # reuse existing subscription if empty
}

variable "vault_name" {
  type        = "string"
  description = "key vault to store auth key of cosmosdb connection"
}

variable "cosmosdb_created" {
  type        = "string"
  description = "output from cosmosdb module, must be true in order to proceed"
}

variable "cosmosdb_settings" {
  type        = "string"
  description = "map of dbname to collections in base64 format, each collection contains list of stored procedures that contains the following values: spName, secretName, secretVersion"
}
