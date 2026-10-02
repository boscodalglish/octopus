#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DOTNET_CLI_TELEMETRY_OPTOUT=1
# Downloads dependencies if absent; never plans against, applies to, or queries Azure.
dotnet restore Octo.slnx --locked-mode
dotnet build Octo.slnx --configuration Release --no-restore
dotnet test Octo.slnx --configuration Release --no-build --logger trx
python3 -m unittest discover -s scripts/tests -v
terraform fmt -check -recursive infrastructure
for root in infrastructure/bootstrap infrastructure/environments/demo; do
  terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly
  terraform -chdir="$root" validate
done
terraform -chdir=infrastructure/bootstrap test
terraform -chdir=infrastructure/environments/demo test
