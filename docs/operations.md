# Operations and incident runbook

## Signals and ownership

The application emits structured JSON logs and, when its telemetry connection string is configured, Application Insights request/exception/dependency telemetry. Local development has no telemetry destination. Avoid logging payloads, tokens, secrets or personal information. The sample endpoints only use synthetic data.

Terraform provisions a 30-day Log Analytics workspace, Application Insights, app/slot diagnostic settings and an operations workbook. The workbook shows requests, failures and p95 latency by instance. The slots share a workspace in this exercise; scope investigations to the hostname/instance and release time. At larger scale, emit explicit environment/release dimensions and use separate production workspaces where required.

| Signal | Demo threshold | Action |
|---|---|---|
| Standard availability test | Health endpoint fails in at least two of three locations | Investigate reachability, TLS, application health and last release |
| HTTP 5xx | More than five in five minutes | Check exceptions, dependency errors and configuration |
| HTTP response time | Average above two seconds for five minutes | Inspect slow requests, resource pressure and dependency latency |

Alerts notify the configured action-group email. Confirm notification delivery after real deployment. Thresholds are demonstration values, not SLOs. Standard availability tests incur costs. The 1 GB/day workspace cap limits costs but can create monitoring gaps; production needs budget/ingestion alerts and an explicit retention policy instead of relying on this cap.

Example workspace investigation query:

```kusto
AppRequests
| where TimeGenerated > ago(30m)
| summarize Requests=count(), Failures=countif(Success == false), P95ms=percentile(DurationMs, 95)
    by bin(TimeGenerated, 5m), AppRoleInstance
```

```kusto
AppExceptions
| where TimeGenerated > ago(30m)
| project TimeGenerated, AppRoleInstance, OperationId, ExceptionType, OuterMessage
| order by TimeGenerated desc
```

## Failed deployment

1. Inspect pipeline failure and the expected commit artifact. A healthy endpoint with the wrong commit fails verification.
2. If package deployment or staging verification fails, promotion stops. Live has not been swapped.
3. A successful swap is followed by live health and commit verification. If that fails, the script first checks that staging still contains the healthy previous commit, swaps back, and verifies recovery. The release remains failed even when rollback succeeds.
4. A failed swap command can have an ambiguous result. The script does **not** blindly swap again. Inspect live and staging `/api/info` plus Azure operation status, establish where each version is, and make a deliberate recovery decision.
5. First deployment has no known-good rollback version. It requires explicit `initialDeployment: true`; a failure needs investigation/redeployment. Never use this flag to bypass an unexplained unhealthy existing deployment.

The service-connection exclusive lock is held through the entire release stage, preventing concurrent pipeline releases from overwriting staging. Restrict out-of-band deployment rights too: a direct portal/CLI change by an administrator is outside this lock.

## Incident response

- Establish user impact, timestamps, affected endpoint and current commit. Assign an incident owner.
- Compare the onset with application deployment, infrastructure/configuration changes and platform events.
- Check availability probes, Azure service health, App Service instance health, logs and dependencies. An alert is a symptom, not a root cause.
- Restore service using the known-good application release when evidence points to a code regression. Keep the approval/incident trail for emergency actions.
- If the old slot has been overwritten, redeploy a retained known-good ZIP through the same staged verification process; do not rebuild old source and assume it is the identical artifact.
- Preserve failed artifact, commit, plan, approval records, exception correlation IDs and timeline. Record what changed, why controls missed it and the corrective action.

Cancellation, agent loss, Azure control-plane outages or a failed rollback can interrupt automatic recovery. Inspect both slots and verify live manually before marking an incident resolved. Keep a documented emergency operator path for cases where Azure DevOps is unavailable.

## Infrastructure recovery

Application slot rollback does not reverse network, identity, monitoring or resource changes. For an infrastructure failure, inspect the exact saved plan, Terraform state and Azure activity history. Prefer a reviewed corrective change. Restore a state version only after reconciling it with actual resources and coordinating state locking; restoring state alone does not restore infrastructure.

There is no database migration in this exercise. A future database-backed service would need backward-compatible expand/contract migrations and independent data recovery. No cross-region disaster recovery or tested RTO/RPO is claimed.
