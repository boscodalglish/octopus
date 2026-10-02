mock_provider "azurerm" {}

run "secure_web_defaults" {
  command = plan
  module { source = "../../modules/web-app" }
  variables {
    name                  = "octo-test"
    resource_group_name   = "octo-test-rg"
    location              = "uksouth"
    integration_subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/octo-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/integration"
    runtime_identity_ids = {
      live    = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/octo-test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/live"
      staging = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/octo-test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/staging"
    }
    application_insights_connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000000"
    tags                                   = { environment = "test" }
  }
  assert {
    condition     = azurerm_linux_web_app.this.https_only && azurerm_linux_web_app_slot.staging.https_only
    error_message = "Both live and staging must require HTTPS."
  }
  assert {
    condition     = !azurerm_linux_web_app.this.ftp_publish_basic_authentication_enabled && !azurerm_linux_web_app.this.webdeploy_publish_basic_authentication_enabled && !azurerm_linux_web_app_slot.staging.ftp_publish_basic_authentication_enabled && !azurerm_linux_web_app_slot.staging.webdeploy_publish_basic_authentication_enabled
    error_message = "Neither slot may enable basic publishing credentials."
  }
  assert {
    condition     = azurerm_linux_web_app.this.site_config[0].minimum_tls_version == "1.2" && azurerm_linux_web_app_slot.staging.site_config[0].minimum_tls_version == "1.2"
    error_message = "Both slots must enforce TLS 1.2 or later."
  }
  assert {
    condition     = azurerm_linux_web_app.this.identity[0].identity_ids != azurerm_linux_web_app_slot.staging.identity[0].identity_ids
    error_message = "Live and staging must have distinct runtime identities."
  }
  assert {
    condition     = azurerm_linux_web_app.this.site_config[0].health_check_path == "/health" && azurerm_linux_web_app_slot.staging.site_config[0].health_check_path == "/health"
    error_message = "Both slots must expose platform health checks."
  }
}

run "delegated_network" {
  command = plan
  module { source = "../../modules/networking" }
  variables {
    name                = "octo-test"
    resource_group_name = "octo-test-rg"
    location            = "uksouth"
    tags                = { environment = "test" }
  }
  assert {
    condition     = azurerm_subnet.integration.delegation[0].service_delegation[0].name == "Microsoft.Web/serverFarms"
    error_message = "The integration subnet must be delegated to App Service."
  }
}

run "complete_platform_graph" {
  command = plan
  variables {
    subscription_id     = "11111111-1111-1111-1111-111111111111"
    name                = "octo-test"
    resource_group_name = "octo-test-rg"
    location            = "uksouth"
    alert_email         = "operations@example.invalid"
    runtime_identity_ids = {
      live    = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/octo-test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/live"
      staging = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/octo-test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/staging"
    }
  }
}
