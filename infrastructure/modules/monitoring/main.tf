resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name}-logs"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
  tags                = var.tags
}
resource "azurerm_application_insights" "this" {
  name                = "${var.name}-insights"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  retention_in_days   = 30
  tags                = var.tags
}
resource "azurerm_monitor_action_group" "this" {
  name                = "${var.name}-operations"
  resource_group_name = var.resource_group_name
  short_name          = "octo-ops"
  tags                = var.tags
  email_receiver {
    name          = "operations"
    email_address = var.alert_email
  }
}
resource "azurerm_monitor_metric_alert" "server_errors" {
  name                = "${var.name}-http-5xx"
  resource_group_name = var.resource_group_name
  scopes              = [var.web_app_id]
  description         = "More than five HTTP 5xx responses in five minutes. See docs/operations.md."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }
  action { action_group_id = azurerm_monitor_action_group.this.id }
}
resource "azurerm_monitor_metric_alert" "latency" {
  name                = "${var.name}-latency"
  resource_group_name = var.resource_group_name
  scopes              = [var.web_app_id]
  description         = "Average HTTP response time above two seconds for five minutes."
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2
  }
  action { action_group_id = azurerm_monitor_action_group.this.id }
}
resource "azurerm_monitor_diagnostic_setting" "app" {
  for_each                   = var.diagnostic_targets
  name                       = "application-logs"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_metric { category = "AllMetrics" }
}
resource "azurerm_application_insights_workbook" "this" {
  name                = uuidv5("url", "https://octo.example/${var.name}/operations")
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "${var.name} operations"
  tags                = var.tags
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [{
      type = 3
      content = {
        version                 = "KqlItem/1.0"
        query                   = "AppRequests | where TimeGenerated > ago(1h) | summarize Requests=count(), Failures=countif(Success == false), P95ms=percentile(DurationMs,95) by bin(TimeGenerated,5m), AppRoleInstance"
        size                    = 0
        title                   = "Requests, failures and p95 latency"
        queryType               = 0
        resourceType            = "microsoft.operationalinsights/workspaces"
        crossComponentResources = [azurerm_log_analytics_workspace.this.id]
        visualization           = "table"
      }
      name = "service-overview"
    }]
  })
}

resource "azurerm_application_insights_standard_web_test" "health" {
  name                    = "${var.name}-availability"
  resource_group_name     = var.resource_group_name
  location                = var.location
  application_insights_id = azurerm_application_insights.this.id
  geo_locations           = ["emea-nl-ams-azr", "emea-gb-db3-azr", "emea-fr-pra-edge"]
  frequency               = 300
  timeout                 = 30
  enabled                 = true
  retry_enabled           = true
  tags                    = var.tags
  request { url = "${var.application_url}/health" }
  validation_rules {
    expected_status_code        = 200
    ssl_check_enabled           = true
    ssl_cert_remaining_lifetime = 7
    content {
      content_match      = "Healthy"
      ignore_case        = false
      pass_if_text_found = true
    }
  }
}
resource "azurerm_monitor_metric_alert" "availability" {
  name                = "${var.name}-unavailable"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights_standard_web_test.health.id, azurerm_application_insights.this.id]
  description         = "Health endpoint fails in two or more probe locations."
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags
  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.health.id
    component_id          = azurerm_application_insights.this.id
    failed_location_count = 2
  }
  action { action_group_id = azurerm_monitor_action_group.this.id }
}
