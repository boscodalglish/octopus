variable "name" { type = string }
variable "project_id" { type = string }
variable "repository_id" { type = string }
variable "approver_ids" { type = set(string) }
variable "infrastructure_connection_id" { type = string }
variable "application_connection_id" { type = string }
variable "infrastructure_connection_name" { type = string }
variable "application_connection_name" { type = string }
variable "resource_group_name" { type = string }
variable "state_account_name" { type = string }
variable "subscription_id" { type = string }
variable "location" { type = string }
variable "runtime_identity_ids" { type = object({ live = string, staging = string }) }
variable "alert_email" { type = string }
