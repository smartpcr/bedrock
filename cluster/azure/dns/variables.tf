variable "subscription_id" {
  type    = "string"
  default = ""       # reuse existing subscription if empty
}

variable "resource_group_name" {
  type = "string"
}

variable "name" {
  type        = "string"
  description = "name of dns zone, redirect traffic under a zone, i.e. dev.1cs.io"
}

variable "service_principal_object_id" {
  type        = "string"
  description = "service principal object id who can read and write dns text records"
}

variable "caa_issuer" {
  type        = "string"
  description = "name of issuer that can be trusted, i.e. letsencrypt.org"
}

variable "env_name" {
  type        = "string"
  default     = "dev"
  description = "name of targeting env"
}
