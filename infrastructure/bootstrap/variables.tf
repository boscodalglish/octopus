variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,24}$", var.name))
    error_message = "Use 4-25 lowercase letters, digits or hyphens, starting with a letter."
  }
}
variable "location" {
  type    = string
  default = "uksouth"
}
variable "state_account_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.state_account_name))
    error_message = "Storage account names require 3-24 lowercase letters or digits."
  }
}
variable "subscription_id" { type = string }
variable "subscription_name" { type = string }
variable "tenant_id" { type = string }
variable "azuredevops_org_url" { type = string }
variable "project_id" { type = string }
variable "repository_id" { type = string }
variable "approver_ids" {
  type = set(string)
  validation {
    condition     = length(var.approver_ids) > 0
    error_message = "Provide at least one independent Azure DevOps approver ID."
  }
}
variable "alert_email" {
  type = string
  validation {
    condition     = can(regex("^[^@ ]+@[^@ ]+\\.[^@ ]+$", var.alert_email))
    error_message = "Provide an operations email address."
  }
}
variable "tags" {
  type    = map(string)
  default = { environment = "demo", application = "octo", managed_by = "terraform", data_classification = "synthetic" }
}
