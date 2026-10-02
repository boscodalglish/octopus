variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "integration_subnet_id" { type = string }
variable "runtime_identity_ids" { type = object({ live = string, staging = string }) }
variable "application_insights_connection_string" {
  type      = string
  sensitive = true
}
variable "tags" { type = map(string) }
