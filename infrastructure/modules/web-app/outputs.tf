output "id" { value = azurerm_linux_web_app.this.id }
output "slot_id" { value = azurerm_linux_web_app_slot.staging.id }
output "name" { value = azurerm_linux_web_app.this.name }
output "url" { value = "https://${azurerm_linux_web_app.this.default_hostname}" }
output "staging_url" { value = "https://${azurerm_linux_web_app_slot.staging.default_hostname}" }
