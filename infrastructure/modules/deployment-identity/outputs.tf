output "client_id" { value = azuread_application.this.client_id }
output "principal_id" { value = azuread_service_principal.this.object_id }
output "service_connection_id" { value = azuredevops_serviceendpoint_azurerm.this.id }
output "service_connection_name" { value = azuredevops_serviceendpoint_azurerm.this.service_endpoint_name }
