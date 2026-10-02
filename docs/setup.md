# Setup and future deployment

This guide describes future deployment. **No commands in this guide were executed against Azure or Azure DevOps as part of this local submission.** Do not use an unrelated corporate tenant or subscription.

## Local-only verification

Install .NET SDK 10.0.401, Terraform 1.12.2, Python 3, Bash, curl and unzip. Run `bash scripts/validate-local.sh`. Linux/WSL is the supported script environment; Windows users can use WSL. For a fresh workstation it downloads public NuGet packages and provider binaries. Provider mocks ensure Terraform tests do not use real credentials.

Optional local security scan:

```bash
bash scripts/install-trivy.sh .tools
.tools/trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL \
  --skip-dirs .git --skip-dirs .tools --skip-dirs artifacts \
  --skip-dirs '**/.terraform' --skip-dirs '**/bin' --skip-dirs '**/obj' \
  --ignorefile .trivyignore.yaml --exit-code 1 .
```

The scanner downloads public vulnerability/advisory data. Downloads are not Azure deployment. The pipeline pins tool versions and checks downloaded archives against upstream checksums; production should additionally verify signed provenance or use a trusted tool image.

## Future prerequisites

1. A personal/test Azure subscription and tenant with budget and permission to deploy these resources.
2. An Azure DevOps organization, project and Azure Repos repository already seeded with this code on `main`. These are existing organizational boundaries, not resources silently created by the exercise.
3. An independent approver/reviewer in that project; hosted-agent capacity; permission to manage pipelines, policies, environments and service connections.
4. Bootstrap authority in **both** Azure and Entra. Azure Contributor plus appropriately scoped Role Based Access Control Administrator is one possible combination; provider registrations/resource-group creation require subscription-level authority. Azure Owner alone does not grant Entra app administration. Tenant app-registration policy and directory permissions must allow creating and owning the application/service-principal pair. Use temporary elevation where available; do not grant routine pipeline identities these privileges.
5. Azure DevOps provider authentication. For a short exercise, supply an appropriately scoped, short-lived `AZDO_PERSONAL_ACCESS_TOKEN` through a protected environment variable, never tfvars, shell history, or Git. It needs the permissions corresponding to project read, repository policies, build definitions, environments and service endpoints. Revoke it after bootstrap. A centrally managed provider workload identity is preferable for recurring platform automation.
6. App Service .NET 10 availability and S1 capacity in the selected region. Confirm service quotas and pricing before applying. The Terraform provider schema is validated locally, but tenant policy and service runtime support still need a real deployment check.

Bootstrap creates the Azure resources, Entra objects, role assignments, federated credentials and delivery configuration through Terraform modules. No portal-created service principal or client secret is required. Entra/admin consent that is needed to authorize the bootstrap executor itself is an external prerequisite, not something Terraform can self-grant.

## Bootstrap sequence (future use only)

Authenticate explicitly to the intended tenant/subscription, then verify it yourself. Do not rely on a workstation's default subscription.

```bash
az login --tenant YOUR_TENANT_ID
az account set --subscription YOUR_PERSONAL_TEST_SUBSCRIPTION_ID
az account show --query '{subscription:id,tenant:tenantId}'
cp infrastructure/bootstrap/terraform.tfvars.example infrastructure/bootstrap/terraform.tfvars
```

Replace **all** placeholders. `name` becomes the globally unique web app name. `state_account_name` must also be globally unique. `approver_ids` are Azure DevOps identity IDs; use the correct project identities, not email strings. Set `alert_email` to a monitored address in your private tfvars; the checked-in address is deliberately non-deliverable.

After securely supplying Azure DevOps provider authentication:

```bash
terraform -chdir=infrastructure/bootstrap init -input=false -lockfile=readonly
terraform -chdir=infrastructure/bootstrap plan -out=bootstrap.tfplan
# Review creation, scopes and identities before this command.
terraform -chdir=infrastructure/bootstrap apply bootstrap.tfplan
```

The first apply uses local state. `foundation` registers required Azure resource providers explicitly. In a tenant where registration is centrally managed, import those existing registrations into the Terraform resource addresses or remove their management from this module by an explicit platform decision; do not attempt to overwrite organizational ownership blindly. RBAC propagation can delay initial backend access; allow it to settle before retrying initialization.

Migrate the bootstrap state after storage exists:

```bash
terraform -chdir=infrastructure/bootstrap output -json bootstrap_backend | \
  python3 scripts/write-backend-config.py > infrastructure/bootstrap/bootstrap.backend.hcl
cp infrastructure/bootstrap/backend.tf.example infrastructure/bootstrap/backend.tf
terraform -chdir=infrastructure/bootstrap init -migrate-state \
  -backend-config=bootstrap.backend.hcl
```

A backend HCL config file is generated from nonsecret outputs. After confirming the remote state is readable and complete, securely remove unneeded local state/plan backups according to your retention policy. Keep the `backend.tf` declaration as code; backend inputs remain local/ignored. The operator has explicit Blob Data Contributor access; Azure control-plane Contributor alone would not suffice for Entra-authenticated blob state access.

## Platform provisioning and application release

Bootstrap creates two pipeline definitions and supplies their nonsecret configuration variables. It also configures environment approvals, protected-main checks, branch policies and explicit per-pipeline service-connection authorization.

1. Run the **infrastructure** pipeline from `main`. Review its saved plan artifact, then have the independent approver approve the apply environment. No bootstrap resources are changed by this pipeline.
2. Run the **application** pipeline from `main`. For the first release only, set `initialDeployment: true` after confirming the web app has no known-good deployment. The normal default is false.
3. Inspect test/scanning artifacts, then approve the release environment. Staging deployment, exact-commit smoke test, swap and live smoke test run under one lock.
4. Read the actual `application_url` Terraform output or App Service hostname after deployment. No placeholder URL in this repository represents a working deployment.
5. Subsequent changes go through PR validation and review. Normal application releases must establish a healthy previous version before deploying.

Infrastructure variables are generated as JSON on the build agent to avoid fragile shell interpolation. Plan and apply use fresh federated tokens from their own AzureCLI tasks; credentials are never persisted as backend arguments or pipeline artifacts. Long-running operations may need a token-refresh-aware Terraform task in a larger platform.

## Cleanup and recovery

Delete platform resources first through a reviewed Terraform destroy plan under authorized execution. Do not use the ordinary application identity. Retain release and state evidence as required.

State resources intentionally have `prevent_destroy` guards. Do not remove those guards merely to make a destroy succeed. To decommission the foundation: verify all dependent resources are removed, export/preserve state securely, migrate bootstrap state to an approved remaining backend or local protected file, review removal of the guards, then destroy the foundation. Otherwise the backend would disappear while Terraform still needs it. Subscription resource-provider registrations may be shared; preserve their registration and remove only this module's ownership if other workloads use them.

Paid hosting continues while the plan exists. There is no automatic cloud cleanup job and no cloud infrastructure to clean up for this local-only exercise.
