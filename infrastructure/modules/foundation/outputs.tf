output "application_resource_group_id" { value = azurerm_resource_group.application.id }
output "application_resource_group_name" { value = azurerm_resource_group.application.name }
output "state_resource_group_name" { value = azurerm_resource_group.state.name }
output "state_account_name" { value = azurerm_storage_account.state.name }
output "platform_state_scope" { value = "${azurerm_storage_account.state.id}/blobServices/default/containers/platform" }
output "runtime_identity_ids" { value = { for key, identity in azurerm_user_assigned_identity.runtime : key => identity.id } }
