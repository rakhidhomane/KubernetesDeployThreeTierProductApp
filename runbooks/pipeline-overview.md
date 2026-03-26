# Pipeline Overview

This document describes the end-to-end CI/CD pipeline for the three-tier
product application.

---

## Pipeline stages

```
┌───────────────────────────────────────────────────────────────┐
│  Developer push / pull request                                │
└───────────────────┬───────────────────────────────────────────┘
                    │
          ┌─────────▼──────────┐
          │  1. YAML Lint &    │  (.github/workflows/CkeckingVersion.yml)
          │  API version check │
          └─────────┬──────────┘
                    │
          ┌─────────▼──────────┐
          │  2. Security scan  │  (.github/workflows/k8s-security-scan.yml)
          │  Trivy + kubesec   │
          └─────────┬──────────┘
                    │
          ┌─────────▼──────────┐
          │  3. (optional)     │  Manual or triggered step
          │  Deploy to cluster │  (deploy.sh / kubectl apply)
          └────────────────────┘
```

### Stage 1 — YAML Lint & Kubernetes API version check

**Workflow file:** `.github/workflows/CkeckingVersion.yml`

| Step | Tool | What it checks |
|------|------|----------------|
| YAML syntax | `yamllint` | Formatting, indentation, line length |
| Deprecated APIs | `pluto` | Kubernetes API versions removed in 1.26–1.30 |
| Removed APIs | `pluto --only-show-removed` | APIs completely removed |

**Trigger:** Any push or PR that modifies a `.yaml` / `.yml` file.

---

### Stage 2 — Security scan

**Workflow file:** `.github/workflows/k8s-security-scan.yml`

| Step | Tool | What it checks |
|------|------|----------------|
| Misconfiguration table | `trivy config` | HIGH/CRITICAL findings (printed to log) |
| Misconfiguration SARIF | `trivy config` | SARIF uploaded to GitHub Security tab |
| Deployment score | `kubesec` | Negative score = critical security issue |

**Trigger:** Same as Stage 1.

---

### Stage 3 — Deploy (manual)

Deployment is performed manually with `deploy.sh` or `deploytwo.sh`.
A future enhancement could automate this with a `workflow_dispatch` trigger
or a CD tool such as Argo CD or Flux.

---

## Workflow files at a glance

```
.github/workflows/
├── CkeckingVersion.yml     # YAML lint + deprecated API check
└── k8s-security-scan.yml   # Trivy + kubesec security scan
```

---

## Adding a new pipeline stage

1. Create a new workflow file under `.github/workflows/`.
2. Reuse the existing `actions/checkout@v4` step.
3. Add the new job and document it in this file.
4. Add a troubleshooting entry to [troubleshooting.md](troubleshooting.md).
