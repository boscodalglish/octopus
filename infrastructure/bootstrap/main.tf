module "foundation" {
  source             = "../modules/foundation"
  name               = var.name
  location           = var.location
  state_account_name = var.state_account_name
  operator_object_id = data.azuread_client_config.current.object_id
  tags               = var.tags
}
module "infrastructure_identity" {
  source            = "../modules/deployment-identity"
  name              = "${var.name}-infrastructure"
  owner_object_id   = data.azuread_client_config.current.object_id
  tenant_id         = var.tenant_id
  subscription_id   = var.subscription_id
  subscription_name = var.subscription_name
  project_id        = var.project_id
  roles = {
    resources = { scope = module.foundation.application_resource_group_id, role = "Contributor" }
    state     = { scope = module.foundation.platform_state_scope, role = "Storage Blob Data Contributor" }
  }
}
module "application_identity" {
  source            = "../modules/deployment-identity"
  name              = "${var.name}-application"
  owner_object_id   = data.azuread_client_config.current.object_id
  tenant_id         = var.tenant_id
  subscription_id   = var.subscription_id
  subscription_name = var.subscription_name
  project_id        = var.project_id
  roles = {
    deploy = { scope = module.foundation.application_resource_group_id, role = "Website Contributor" }
  }
}
module "delivery" {
  source                         = "../modules/delivery-governance"
  name                           = var.name
  project_id                     = var.project_id
  repository_id                  = var.repository_id
  approver_ids                   = var.approver_ids
  infrastructure_connection_id   = module.infrastructure_identity.service_connection_id
  application_connection_id      = module.application_identity.service_connection_id
  infrastructure_connection_name = module.infrastructure_identity.service_connection_name
  application_connection_name    = module.application_identity.service_connection_name
  resource_group_name            = module.foundation.application_resource_group_name
  state_account_name             = module.foundation.state_account_name
  subscription_id                = var.subscription_id
  location                       = var.location
  runtime_identity_ids           = module.foundation.runtime_identity_ids
  alert_email                    = var.alert_email
}
