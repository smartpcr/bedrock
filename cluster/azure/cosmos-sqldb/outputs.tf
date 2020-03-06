output "cosmosdb_created" {
  value = "${join("",null_resource.store_auth_key.*.id)}"
}

output "cosmosdb_collection_created" {
  value = "${join("",null_resource.create_cosmosdb_sql_collections.*.id)}"
}