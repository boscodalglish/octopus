variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "web_app_id" { type = string }
variable "diagnostic_targets" { type = map(string) }
variable "alert_email" { type = string }
variable "tags" { type = map(string) }
variable "application_url" { type = string }
