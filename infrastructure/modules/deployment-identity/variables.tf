variable "name" { type = string }
variable "owner_object_id" { type = string }
variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "subscription_name" { type = string }
variable "project_id" { type = string }
variable "roles" { type = map(object({ scope = string, role = string })) }
