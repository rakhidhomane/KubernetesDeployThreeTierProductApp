# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in this project, please open a
**private security advisory** via the GitHub Security tab rather than a
public issue.  Include:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix

We will acknowledge the report within 48 hours and provide a timeline for a
fix within 7 days.

---

## Secure defaults required for all Kubernetes workloads

All Deployments in this repository must comply with the following controls:

### Container security context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000           # non-zero UID
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

### Resource limits

Every container must define CPU and memory requests **and** limits:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

### Image policy

- Use specific image tags (no `:latest` in production).
- Use images from trusted registries only.
- Enable `imagePullPolicy: Always` for mutable tags.

### Network policies

- Default-deny all ingress and egress (see `networkpolicy/01-default-deny.yaml`).
- Allow only the minimum required traffic using explicit NetworkPolicy rules.

### Secrets management

- Do **not** commit plaintext secrets.
- Use Kubernetes Secrets (base64-encoded) only as a starting point for dev.
- In production use an external secrets provider (e.g., AWS Secrets Manager,
  HashiCorp Vault, or External Secrets Operator).

---

## Compliance checks

| Control | Tool | Config |
|---------|------|--------|
| Kubernetes misconfiguration | Trivy | `.trivyignore` |
| Deployment security score | kubesec | Inline |
| IaC misconfiguration | Checkov | `security/checkov/.checkov.yaml` |
| OPA policy violations | OPA | `security/opa-policies/` |

All checks run automatically in GitHub Actions on every pull request.

---

## Accepted risks & exceptions

Any deviation from the above defaults must be:

1. Documented in `.trivyignore` with a comment explaining the risk acceptance.
2. Approved by a maintainer before merging.
3. Reviewed quarterly.

Current exceptions are listed in [`.trivyignore`](../.trivyignore).
