mock_provider "azuredevops" {
  mock_resource "azuredevops_build_definition" { defaults = { id = "42" } }
  mock_resource "azuredevops_environment" { defaults = { id = "12" } }
}
mock_provider "azuread" {
  mock_data "azuread_client_config" {
    defaults = { object_id = "77777777-7777-7777-7777-777777777777" }
  }
}
mock_provider "azurerm" {}

run "release_governance" {
  command = plan
  module { source = "../modules/delivery-governance" }
  variables {
    name                           = "octo-test"
    project_id                     = "11111111-1111-1111-1111-111111111111"
    repository_id                  = "22222222-2222-2222-2222-222222222222"
    approver_ids                   = ["33333333-3333-3333-3333-333333333333"]
    infrastructure_connection_id   = "44444444-4444-4444-4444-444444444444"
    application_connection_id      = "55555555-5555-5555-5555-555555555555"
    infrastructure_connection_name = "test-infrastructure"
    application_connection_name    = "test-application"
    resource_group_name            = "octo-test-rg"
    state_account_name             = "octoteststate"
    subscription_id                = "66666666-6666-6666-6666-666666666666"
    location                       = "uksouth"
    runtime_identity_ids           = { live = "live-identity", staging = "staging-identity" }
    alert_email                    = "operations@example.invalid"
  }
  assert {
    condition     = !azuredevops_check_approval.this["release"].requester_can_approve && !azuredevops_check_approval.this["infrastructure"].requester_can_approve
    error_message = "Release and infrastructure approvals must require another person."
  }
  assert {
    condition     = azuredevops_check_branch_control.connection["application"].allowed_branches == "refs/heads/main" && azuredevops_check_branch_control.connection["application"].verify_branch_protection
    error_message = "Application credentials must only be usable from protected main."
  }
  assert {
    condition     = !azuredevops_branch_policy_min_reviewers.main.settings[0].submitter_can_vote && azuredevops_branch_policy_min_reviewers.main.settings[0].last_pusher_cannot_approve
    error_message = "PR authors and last pushers cannot approve their own changes."
  }
  assert {
    condition     = length(azuredevops_pipeline_authorization.connection) == 2 && length(azuredevops_check_exclusive_lock.connection) == 2
    error_message = "Each deployment connection requires explicit pipeline authorization and a stage lock."
  }
}

run "complete_bootstrap_graph" {
  command = plan
  variables {
    name                = "octo-test"
    state_account_name  = "octoteststate"
    location            = "uksouth"
    subscription_id     = "11111111-1111-1111-1111-111111111111"
    subscription_name   = "Synthetic test subscription"
    tenant_id           = "22222222-2222-2222-2222-222222222222"
    azuredevops_org_url = "https://dev.azure.com/synthetic-test"
    project_id          = "33333333-3333-3333-3333-333333333333"
    repository_id       = "44444444-4444-4444-4444-444444444444"
    approver_ids        = ["55555555-5555-5555-5555-555555555555"]
    alert_email         = "operations@example.invalid"
  }
}
