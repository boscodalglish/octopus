output "application_url" { value = module.web_app.url }
output "staging_url" { value = module.web_app.staging_url }
output "application_name" { value = module.web_app.name }
output "log_analytics_workspace_id" { value = module.monitoring.workspace_id }
