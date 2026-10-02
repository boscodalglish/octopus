module "networking" {
  source              = "../../modules/networking"
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
module "web_app" {
  source                                 = "../../modules/web-app"
  name                                   = var.name
  resource_group_name                    = var.resource_group_name
  location                               = var.location
  integration_subnet_id                  = module.networking.integration_subnet_id
  runtime_identity_ids                   = var.runtime_identity_ids
  application_insights_connection_string = module.monitoring.connection_string
  tags                                   = var.tags
}
module "monitoring" {
  source              = "../../modules/monitoring"
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  web_app_id          = module.web_app.id
  application_url     = module.web_app.url
  diagnostic_targets  = { live = module.web_app.id, staging = module.web_app.slot_id }
  alert_email         = var.alert_email
  tags                = var.tags
}
