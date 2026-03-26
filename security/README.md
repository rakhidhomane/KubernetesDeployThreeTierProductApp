# Security Policies

This directory contains security policies and configuration files used to
enforce infrastructure and Kubernetes security standards.

| Item | Description |
|------|-------------|
| [`opa-policies/`](opa-policies/) | Open Policy Agent (OPA) Rego policies for Kubernetes manifests |
| [`checkov/`](checkov/) | Checkov custom configuration |
| [`SECURITY-POLICY.md`](SECURITY-POLICY.md) | Human-readable security policy for this project |

---

## Running policies locally

```bash
# OPA — evaluate all policies against a manifest
opa eval \
  --data security/opa-policies/ \
  --input backend/backend-deployment.yaml \
  "data.kubernetes.deny"

# Checkov — IaC scan with custom config
checkov --config-file security/checkov/.checkov.yaml

# Trivy — misconfiguration scan (uses .trivyignore in repo root)
trivy config . --severity HIGH,CRITICAL
```

See the [security scan runbook](../runbooks/security-scan.md) for full details.
