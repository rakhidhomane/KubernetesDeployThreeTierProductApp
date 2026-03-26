# Security Scan Runbook

This runbook explains how to run the security scans locally and how to
interpret and action the results.

---

## Automated scans (GitHub Actions)

Two workflows run automatically on every push / PR that touches YAML files:

| Workflow | File | Tools |
|----------|------|-------|
| Kubernetes Security Scan | `.github/workflows/k8s-security-scan.yml` | Trivy (config), kubesec |
| YAML & API version check | `.github/workflows/CkeckingVersion.yml` | yamllint, pluto |

Results from Trivy are uploaded to the **Security → Code scanning** tab of the
repository as a SARIF report.

---

## Run Trivy locally

```bash
# Scan all manifests for HIGH/CRITICAL misconfigurations
trivy config . \
  --severity HIGH,CRITICAL \
  --trivyignores .trivyignore \
  --format table

# Scan Terraform IaC
trivy config iac/terraform --severity HIGH,CRITICAL --format table
```

### Suppress a known false-positive

Add the AVD/CVE ID to `.trivyignore`:

```
# Example: suppress a known finding
AVD-KSV-0036
```

See the existing `.trivyignore` for examples.

---

## Run kubesec locally

```bash
kubesec scan backend/backend-deployment.yaml
kubesec scan frontend/frontend-deployment.yaml
kubesec scan database/mysql-deployment.yaml
```

A **positive score** means the manifest passes basic hardening.  A **negative
score** indicates critical security issues that should be fixed before
deploying to production.

Common fixes:

| Issue | Fix |
|-------|-----|
| `runAsNonRoot` not set | Add `securityContext.runAsNonRoot: true` |
| Capabilities not dropped | Add `securityContext.capabilities.drop: ["ALL"]` |
| Root filesystem writable | Add `securityContext.readOnlyRootFilesystem: true` |

---

## Run Checkov locally (IaC)

```bash
# Terraform
checkov -d iac/terraform --framework terraform

# Kubernetes manifests
checkov -d . --framework kubernetes

# Show only failed checks
checkov -d . --framework kubernetes --compact
```

---

## Run OPA policies locally

```bash
# Evaluate a single policy against a manifest
opa eval \
  --data security/opa-policies/ \
  --input backend/backend-deployment.yaml \
  "data.kubernetes.deny"
```

---

## Interpreting results

| Severity | Action |
|----------|--------|
| CRITICAL | Must be fixed before merge |
| HIGH | Should be fixed; document justification in `.trivyignore` if deferred |
| MEDIUM / LOW | Address in next sprint; track in issue |

---

## Keeping `.trivyignore` clean

Review `.trivyignore` in every quarterly security review:

1. List suppressed findings: `cat .trivyignore`
2. Re-run Trivy without the ignore file: `trivy config . --severity HIGH,CRITICAL`
3. For each suppressed item, confirm it is still a known/accepted risk.
4. Remove entries that are no longer valid.
