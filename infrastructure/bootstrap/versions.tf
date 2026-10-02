terraform {
  required_version = ">= 1.12.2, < 2.0"
  required_providers {
    azurerm     = { source = "hashicorp/azurerm", version = "~> 4.0" }
    azuread     = { source = "hashicorp/azuread", version = "~> 3.0" }
    azuredevops = { source = "microsoft/azuredevops", version = "~> 1.0" }
  }
  # Initial local state; add backend.tf from backend.tf.example AFTER provisioning.
}
provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}
provider "azuread" { tenant_id = var.tenant_id }
provider "azuredevops" { org_service_url = var.azuredevops_org_url }
data "azuread_client_config" "current" {}
