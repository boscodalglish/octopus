locals {
  connections = {
    application    = var.application_connection_id
    infrastructure = var.infrastructure_connection_id
  }
  variables = {
    applicationServiceConnection    = var.application_connection_name
    infrastructureServiceConnection = var.infrastructure_connection_name
    applicationName                 = var.name
    resourceGroupName               = var.resource_group_name
    stateAccountName                = var.state_account_name
    subscriptionId                  = var.subscription_id
    location                        = var.location
    liveIdentityId                  = var.runtime_identity_ids.live
    stagingIdentityId               = var.runtime_identity_ids.staging
    alertEmail                      = var.alert_email
    releaseEnvironment              = "${var.name}-release"
    infrastructureEnvironment       = "${var.name}-infrastructure"
  }
}
resource "azuredevops_environment" "this" {
  for_each   = toset(["release", "infrastructure"])
  project_id = var.project_id
  name       = "${var.name}-${each.value}"
}
resource "azuredevops_check_approval" "this" {
  for_each                   = azuredevops_environment.this
  project_id                 = var.project_id
  target_resource_id         = each.value.id
  target_resource_type       = "environment"
  approvers                  = var.approver_ids
  requester_can_approve      = false
  minimum_required_approvers = 1
  instructions               = "Review the commit, checks and artifacts. For infrastructure inspect the saved plan."
  timeout                    = 1440
}
resource "azuredevops_check_branch_control" "connection" {
  for_each                         = local.connections
  project_id                       = var.project_id
  target_resource_id               = each.value
  target_resource_type             = "endpoint"
  display_name                     = "Protected main only"
  allowed_branches                 = "refs/heads/main"
  verify_branch_protection         = true
  ignore_unknown_protection_status = false
}
# Hold the connection lock for the whole release stage: staging, swap and recovery.
resource "azuredevops_check_exclusive_lock" "connection" {
  for_each             = local.connections
  project_id           = var.project_id
  target_resource_id   = each.value
  target_resource_type = "endpoint"
  timeout              = 120
}
resource "azuredevops_build_definition" "this" {
  for_each   = toset(["application", "infrastructure"])
  project_id = var.project_id
  name       = "${var.name}-${each.value}"
  path       = "\\Octo"
  ci_trigger { use_yaml = true }
  repository {
    repo_type   = "TfsGit"
    repo_id     = var.repository_id
    branch_name = "refs/heads/main"
    yml_path    = "pipelines/${each.value}.yml"
  }
  dynamic "variable" {
    for_each = local.variables
    content {
      name           = variable.key
      value          = variable.value
      allow_override = false
    }
  }
}
resource "azuredevops_pipeline_authorization" "connection" {
  for_each    = local.connections
  project_id  = var.project_id
  resource_id = each.value
  type        = "endpoint"
  pipeline_id = azuredevops_build_definition.this[each.key].id
}
resource "azuredevops_pipeline_authorization" "environment" {
  for_each    = { application = "release", infrastructure = "infrastructure" }
  project_id  = var.project_id
  resource_id = azuredevops_environment.this[each.value].id
  type        = "environment"
  pipeline_id = azuredevops_build_definition.this[each.key].id
}
resource "azuredevops_branch_policy_min_reviewers" "main" {
  project_id = var.project_id
  enabled    = true
  blocking   = true
  settings {
    reviewer_count                         = 1
    submitter_can_vote                     = false
    last_pusher_cannot_approve             = true
    on_push_reset_approved_votes           = true
    allow_completion_with_rejects_or_waits = false
    scope {
      repository_id  = var.repository_id
      repository_ref = "refs/heads/main"
      match_type     = "Exact"
    }
  }
}
resource "azuredevops_branch_policy_build_validation" "main" {
  project_id = var.project_id
  enabled    = true
  blocking   = true
  settings {
    display_name        = "Application, IaC and security validation"
    build_definition_id = azuredevops_build_definition.this["application"].id
    valid_duration      = 0
    scope {
      repository_id  = var.repository_id
      repository_ref = "refs/heads/main"
      match_type     = "Exact"
    }
  }
}
