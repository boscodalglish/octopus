#!/usr/bin/env python3
"""Write nonsecret environment inputs without shell interpolation of JSON."""
import json
import os
from pathlib import Path

values = {
    "subscription_id": os.environ["DEPLOY_SUBSCRIPTION_ID"],
    "name": os.environ["DEPLOY_APP_NAME"],
    "resource_group_name": os.environ["DEPLOY_RESOURCE_GROUP"],
    "location": os.environ["DEPLOY_LOCATION"],
    "runtime_identity_ids": {
        "live": os.environ["DEPLOY_LIVE_IDENTITY"],
        "staging": os.environ["DEPLOY_STAGING_IDENTITY"],
    },
    "alert_email": os.environ["DEPLOY_ALERT_EMAIL"],
}
Path("infrastructure/environments/demo/pipeline.auto.tfvars.json").write_text(json.dumps(values, indent=2))
