# Validation and submission status

Validation date: **2026-09-30**. All checks below ran locally. Terraform used provider mocks for every test run; no real Azure plan/apply or Azure DevOps execution was performed.

| Check | Result |
|---|---|
| .NET restore with locked dependencies and vulnerability auditing | Passed |
| Release build with warnings as errors | Passed |
| ASP.NET integration tests | **4 passed**: health, release identity/headers, home page and unknown route |
| Python release/smoke tests | **12 passed**: exact commit checks, unhealthy/malformed responses, deployment/staging failures, successful promotion, rollback, first deployment and ambiguous swap failure |
| Bootstrap Terraform validate | Passed with AzureRM 4.81.0, AzureAD 3.10.0 and AzureDevOps 1.16.0 |
| Platform Terraform validate | Passed with AzureRM 4.81.0 |
| Mocked bootstrap tests | **2 passed**: approval/branch/authorization assertions and complete bootstrap dependency graph |
| Mocked platform tests | **3 passed**: secure slot defaults, subnet delegation and complete platform dependency graph |
| Terraform formatting | Passed |
| Pipeline YAML parsing and Bash syntax checks | Passed; syntax checks are not Azure DevOps execution |
| Published app over actual loopback HTTP | Passed health and exact embedded commit verification |
| Trivy 0.74.0 dependency/secret/IaC scan | No unsuppressed HIGH/CRITICAL findings; one reviewed state-network exception, expiring 2026-10-31 |

.NET SDK: **10.0.401**. Terraform CLI: **1.12.2**. NuGet and Terraform provider lockfiles are included. The published-app test launched a process on loopback, verified it and stopped it; no background application server remains running from this verification.

Raw local logs and scanner output are in the gitignored `artifacts/` directory. The pipeline definitions publish test, scan, application and plan artifacts when executed in a future Azure DevOps environment. No cloud execution or deployment success is inferred from these local results.

## Remaining cloud verification

- Subscription policy, Entra bootstrap permissions, federated service-connection token exchange and Azure DevOps provider authorization.
- Region/runtime/SKU availability, live resource creation, actual diagnostic categories and probe locations.
- ZIP deployment with Entra authentication, actual slot swaps, connectivity and notification delivery.
- Azure DevOps YAML expansion, environment approvals and exclusive-lock behavior under concurrent real runs.
- State migration and effective RBAC boundaries, including denial of bootstrap-state access to the infrastructure identity.

Mocks validate configuration and important invariants, not the behavior or availability of Azure services. These checks must be completed before describing the solution as deployed or production-ready.

## Submission checklist

- [x] Local .NET application, tests and dependency lockfiles.
- [x] Architecture, assumptions, trade-offs, setup and AI-use disclosure.
- [x] Azure DevOps YAML and reusable templates.
- [x] Terraform modules for infrastructure, Entra identities and governance.
- [x] Security controls, scoped scanner exception, operational runbook and recovery tests.
- [x] Git repository prepared for the private `boscodalglish/octopus` submission destination.
- [ ] Interviewer access to the private repository confirmed.
- [ ] Azure deployment and public URL — intentionally not performed under the local-only instruction.

Dockerfile: not applicable to this non-container App Service implementation. Key Vault: not provisioned because the application has no business secrets; the extension approach is documented.
