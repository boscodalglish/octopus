#!/usr/bin/env python3
"""Convert Terraform's nonsecret backend output JSON into a backend HCL file."""
import json
import sys

values = json.load(sys.stdin)
allowed = {"storage_account_name", "container_name", "key", "use_azuread_auth"}
if set(values) != allowed:
    raise SystemExit("Unexpected backend keys; refusing to write configuration")
for key, value in values.items():
    print(f"{key} = {json.dumps(value)}")
