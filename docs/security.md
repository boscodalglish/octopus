# Security and governance

## Implemented controls

| Area | Control | Boundary / caveat |
|---|---|---|
| Deployment authentication | Entra application, service principal, exact federated issuer/subject from the Azure DevOps connection | No stored Azure client secret; federated token is short-lived |
| Authorization | Separate bootstrap, infrastructure, application and runtime identities | Infrastructure Contributor and Website Contributor are still powerful within their scopes |
| State | Entra-only blob access, disabled shared keys, private containers, TLS 1.2, versioning, 30-day soft delete, destroy guards | Public network endpoint for hosted-agent compatibility; see exception |
| Runtime | HTTPS-only, TLS 1.2 on both app/SCM endpoints, disabled FTP/basic publishing | Anonymous synthetic application; not suitable for confidential data as-is |
| Release governance | Protected main, PR reviewer, author/last-pusher restrictions, independent environment approval | Administrators able to change policies remain privileged and require organizational separation |
| Pipeline access | Explicit pipeline authorization, protected-branch checks, connection exclusive locks | Tenant/project permissions and audit retention are organizational prerequisites |
| Supply chain | Pinned SDK, NuGet/provider lockfiles, compiler warnings as errors, NuGet auditing, Trivy | No dedicated CodeQL/SAST campaign or signed artifact attestation in this time box |
| Auditability | Commit embedded in build, test reports, scan report, ZIP SHA-256, plan artifact, approval/deployment history | Configure organizational retention/export before regulated production |

Trivy blocks unsuppressed HIGH/CRITICAL dependency, secret and Terraform findings. NuGet audits direct and transitive dependencies at high/critical severity during restore; warnings are errors. The scan's advisory database evolves, so a future clean build can legitimately fail and require dependency updates. Moderate/low findings should also be triaged under an organization-specific policy. No container image is built, so there is no container scan to misrepresent as executed.

## Demo exception: publicly reachable state storage

`AZU-0012` is suppressed **only** for `infrastructure/modules/foundation/main.tf` in `.trivyignore.yaml`, with expiry **2026-10-31**. Microsoft-hosted runners do not have a stable private network path into the demo subscription. Leaving network reachability public allows the pipeline to use the state backend without granting it firewall-management authority.

This does not make blob contents public: storage keys and anonymous container access are disabled, TLS is required, and only explicitly authorized Entra identities can access state. It is nevertheless a real network-exposure trade-off, not a false positive. This is suitable only for the disposable synthetic demo after review. Production should use private agents, a private endpoint/private DNS and a deny-by-default storage firewall; remove the exception at that point. Do not extend its expiry without reviewing the risk.

## Secrets and configuration

The application has no business secret. Its managed identities have no role assignments because no data service is accessed. The Application Insights connection string is observability routing configuration rather than a business credential; Terraform marks it sensitive, and state/plan artifacts are restricted regardless.

If a real secret is introduced, extend the reviewed modules to create a Key Vault with RBAC, purge protection, private connectivity and diagnostics. Add only the required `Key Vault Secrets User` role for the appropriate slot identity in the privileged access layer. Configure the user-assigned identity used for Key Vault references explicitly, mark environment-specific references sticky, and populate/rotate secret values through an approved secret-management process. Avoid putting secret values into Terraform variables/state. Prefer managed-identity access to the target service instead of introducing a secret when supported.

Bootstrap may use a short-lived Azure DevOps PAT supplied as an environment variable; it is not an application secret and is not checked into code. The provider still has sensitive access and its state must be protected. The deployment pipelines do not use that PAT. Bootstrap records the operator as owner of the created Entra apps/service principals: ownership persists after temporary administrator elevation expires. Review/transfer that ownership explicitly when operationalizing the platform.

## Additional production work

- Private ingress/SCM or an approved public edge with authentication/WAF, plus private-agent deployment connectivity.
- Separate subscriptions/resource groups/state/identities for environments, stricter custom deploy roles and a protected identity-management workflow.
- Azure Policy, PIM, access reviews, central logs and defined retention/evidence export.
- Versioned protected pipeline templates/required-template checks so ordinary YAML changes cannot bypass centrally mandated controls.
- Dedicated SAST, dependency update automation, signed/provenance-verified artifacts and protected build agents.
- App Insights ingestion hardening and telemetry access controls appropriate to the data classification.

These are improvements, not claims of implemented compliance. No specific regulatory standard has been assessed or certified.
