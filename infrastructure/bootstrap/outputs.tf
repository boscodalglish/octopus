output "bootstrap_backend" {
  value = {
    storage_account_name = module.foundation.state_account_name
    container_name       = "bootstrap"
    key                  = "bootstrap.tfstate"
    use_azuread_auth     = true
  }
}
output "platform_inputs" {
  value = {
    subscription_id      = var.subscription_id
    name                 = var.name
    location             = var.location
    resource_group_name  = module.foundation.application_resource_group_name
    runtime_identity_ids = module.foundation.runtime_identity_ids
    alert_email          = var.alert_email
  }
}
output "service_connections" {
  value = {
    infrastructure = module.infrastructure_identity.service_connection_name
    application    = module.application_identity.service_connection_name
  }
}
