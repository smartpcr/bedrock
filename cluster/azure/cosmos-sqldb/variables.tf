variable "resource_group_name" {
  type        = "string"
  description = "The resource group name for this cosmos db"
}

variable "location" {
  description = "The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  type        = "string"
}

variable "alt_location" {
  type = "string"
  description = "The Azure Region which should be used for the alternate location when failed over."
}

variable "cosmos_db_account" {
  type = "string"
  description = "name of cosmosdb account"
}

variable "consistency_level" {
  type = "string"
  description = "cosmosdb consistency level: BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix"
  default = "Session"
}

variable "allowed_ip_ranges" {
  type = "string"
  description = "allowed ip range in addition to azure services and azure portal, i.e. 12.54.145.0/24,13.75.0.0/16"
}


variable "cosmos_db_offer_type" {
  type    = "string"
  default = "Standard"
}

variable "cosmos_db_name" {
  type        = "string"
  description = "CosmosDB name"
}

variable "cosmos_db_collections" {
  type    = "string"
  description = "collections are separated by ';', each entry takes the format: collection_name,partiton_key,throughput"
}
