resource "azuread_application" "this" {
  display_name     = var.name
  owners           = [var.owner_object_id]
  sign_in_audience = "AzureADMyOrg"
}
resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
  owners    = [var.owner_object_id]
}
resource "azuredevops_serviceendpoint_azurerm" "this" {
  project_id                             = var.project_id
  service_endpoint_name                  = var.name
  description                            = "Terraform-managed federated identity; no client secret."
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.subscription_id
  azurerm_subscription_name              = var.subscription_name
  credentials { serviceprincipalid = azuread_application.this.client_id }
}
resource "azuread_application_federated_identity_credential" "this" {
  application_id = azuread_application.this.id
  display_name   = "azure-devops"
  description    = "Trust only the Terraform-managed service connection."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_issuer
  subject        = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_subject
  depends_on     = [azuread_service_principal.this]
}
resource "azurerm_role_assignment" "this" {
  for_each                         = var.roles
  scope                            = each.value.scope
  role_definition_name             = each.value.role
  principal_id                     = azuread_service_principal.this.object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
