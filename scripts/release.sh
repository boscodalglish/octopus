#!/usr/bin/env bash
# Called only by the approved Azure DevOps release stage. Never invoked by local validation.
set -euo pipefail
: "${RESOURCE_GROUP:?}" "${APP_NAME:?}" "${EXPECTED_COMMIT:?}" "${PACKAGE_PATH:?}"
: "${ALLOW_INITIAL_DEPLOYMENT:=false}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
# Obtain actual Azure hostnames, including any platform-generated hostname suffix.
live_host="$(az webapp show -g "$RESOURCE_GROUP" -n "$APP_NAME" --query defaultHostName -o tsv)"
staging_host="$(az webapp show -g "$RESOURCE_GROUP" -n "$APP_NAME" --slot staging --query defaultHostName -o tsv)"
live_url="https://$live_host"
staging_url="https://$staging_host"

read_commit() {
  python3 - "$1" <<'PYCODE'
import json, sys, urllib.request
with urllib.request.urlopen(sys.argv[1] + '/api/info', timeout=15) as response:
    value = json.load(response)
if value.get('service') != 'octo' or not value.get('commit'):
    raise SystemExit('No valid Octo release identity')
print(value['commit'])
PYCODE
}

previous_commit="$(read_commit "$live_url" 2>/dev/null || true)"
if [[ -n "$previous_commit" ]]; then
  python3 "$script_dir/smoke-test.py" "$live_url" "$previous_commit" --attempts 3 --delay 5
elif [[ "${ALLOW_INITIAL_DEPLOYMENT,,}" != true ]]; then
  echo 'Cannot establish a healthy rollback target. Stop; use initialDeployment only for a verified empty app.' >&2
  exit 1
fi

az webapp deploy -g "$RESOURCE_GROUP" -n "$APP_NAME" --slot staging   --src-path "$PACKAGE_PATH" --type zip --clean true --restart true --output none
python3 "$script_dir/smoke-test.py" "$staging_url" "$EXPECTED_COMMIT"

if ! az webapp deployment slot swap -g "$RESOURCE_GROUP" -n "$APP_NAME"   --slot staging --target-slot production --output none; then
  echo 'Swap command failed; completion may be ambiguous. Inspect both slots before any further swap.' >&2
  exit 1
fi

if python3 "$script_dir/smoke-test.py" "$live_url" "$EXPECTED_COMMIT"; then
  echo "Released commit $EXPECTED_COMMIT successfully."
  exit 0
fi

if [[ -z "$previous_commit" ]]; then
  echo 'Initial deployment failed and has no known-good rollback target. Incident investigation required.' >&2
  exit 1
fi
# Ensure staging still holds the expected rollback target before touching traffic.
python3 "$script_dir/smoke-test.py" "$staging_url" "$previous_commit" --attempts 3 --delay 5
az webapp deployment slot swap -g "$RESOURCE_GROUP" -n "$APP_NAME"   --slot staging --target-slot production --output none
python3 "$script_dir/smoke-test.py" "$live_url" "$previous_commit"
echo 'Previous release restored. This release remains FAILED.' >&2
exit 1
