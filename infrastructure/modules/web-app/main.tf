resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "S1"
  worker_count        = 1
  tags                = var.tags
}
locals {
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string
    ASPNETCORE_ENVIRONMENT                = "Production"
    SCM_DO_BUILD_DURING_DEPLOYMENT        = "false"
    WEBSITE_RUN_FROM_PACKAGE              = "1"
  }
}
resource "azurerm_linux_web_app" "this" {
  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  public_network_access_enabled                  = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  virtual_network_subnet_id                      = var.integration_subnet_id
  app_settings                                   = local.app_settings
  tags                                           = var.tags
  identity {
    type         = "UserAssigned"
    identity_ids = [var.runtime_identity_ids.live]
  }
  site_config {
    always_on                         = true
    minimum_tls_version               = "1.2"
    scm_minimum_tls_version           = "1.2"
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 2
    application_stack { dotnet_version = "10.0" }
  }
  sticky_settings { app_setting_names = ["APPLICATIONINSIGHTS_CONNECTION_STRING", "ASPNETCORE_ENVIRONMENT"] }
}
resource "azurerm_linux_web_app_slot" "staging" {
  name                                           = "staging"
  app_service_id                                 = azurerm_linux_web_app.this.id
  https_only                                     = true
  public_network_access_enabled                  = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  virtual_network_subnet_id                      = var.integration_subnet_id
  app_settings                                   = local.app_settings
  tags                                           = var.tags
  identity {
    type         = "UserAssigned"
    identity_ids = [var.runtime_identity_ids.staging]
  }
  site_config {
    always_on                         = true
    minimum_tls_version               = "1.2"
    scm_minimum_tls_version           = "1.2"
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 2
    application_stack { dotnet_version = "10.0" }
  }
}
