# Explicit registration belongs to the privileged bootstrap layer.
resource "azurerm_resource_provider_registration" "this" {
  for_each = toset(["Microsoft.Storage", "Microsoft.ManagedIdentity", "Microsoft.Network", "Microsoft.Web", "Microsoft.Insights", "Microsoft.OperationalInsights"])
  name     = each.value
}
resource "azurerm_resource_group" "state" {
  name     = "${var.name}-state-rg"
  location = var.location
  tags     = var.tags
}
resource "azurerm_resource_group" "application" {
  name     = "${var.name}-app-rg"
  location = var.location
  tags     = var.tags
}
resource "azurerm_storage_account" "state" {
  depends_on                      = [azurerm_resource_provider_registration.this]
  name                            = var.state_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                            = var.tags
  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 30 }
    container_delete_retention_policy { days = 30 }
  }
  lifecycle { prevent_destroy = true }
}
resource "azurerm_storage_container" "state" {
  for_each              = toset(["bootstrap", "platform"])
  name                  = each.value
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
  lifecycle { prevent_destroy = true }
}
resource "azurerm_role_assignment" "bootstrap_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.operator_object_id
}
resource "azurerm_user_assigned_identity" "runtime" {
  depends_on          = [azurerm_resource_provider_registration.this]
  for_each            = toset(["live", "staging"])
  name                = "${var.name}-${each.value}-runtime"
  location            = var.location
  resource_group_name = azurerm_resource_group.application.name
  tags                = var.tags
}
