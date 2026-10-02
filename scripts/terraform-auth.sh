#!/usr/bin/env bash
# Source only inside AzureCLI@2 with addSpnToEnvironment=true and a federated connection.
set -euo pipefail
: "${servicePrincipalId:?Missing federated service connection client ID}"
: "${tenantId:?Missing tenant ID}"
: "${idToken:?Missing OIDC token; client-secret connections are not supported}"
export ARM_CLIENT_ID="$servicePrincipalId"
export ARM_TENANT_ID="$tenantId"
export ARM_OIDC_TOKEN="$idToken"
export ARM_SUBSCRIPTION_ID
ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export ARM_USE_OIDC=true ARM_USE_AZUREAD=true ARM_USE_CLI=false
