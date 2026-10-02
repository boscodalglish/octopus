variable "subscription_id" { type = string }
variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,24}$", var.name))
    error_message = "Use 4-25 lowercase letters, digits or hyphens, starting with a letter."
  }
}
variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "uksouth"
}
variable "runtime_identity_ids" { type = object({ live = string, staging = string }) }
variable "alert_email" { type = string }
variable "tags" {
  type    = map(string)
  default = { environment = "demo", application = "octo", managed_by = "terraform", data_classification = "synthetic" }
}
