# CI/CD Runbooks

This directory contains automation runbooks for the three-tier product application.
Each runbook covers one aspect of the software delivery pipeline.

| Runbook | Description |
|---------|-------------|
| [pipeline-overview.md](pipeline-overview.md) | End-to-end pipeline architecture and stages |
| [build-and-test.md](build-and-test.md) | How to build, test, and lint the application |
| [deploy.md](deploy.md) | Deployment procedures for dev and production |
| [troubleshooting.md](troubleshooting.md) | Common failures, root causes, and fixes |
| [rollback.md](rollback.md) | Rollback procedures for failed deployments |
| [security-scan.md](security-scan.md) | Running and interpreting security scans |

---

## Quick troubleshooting guide

| Symptom | First step | Runbook |
|---------|-----------|---------|
| Build workflow fails | Check `Actions` → last run logs | [troubleshooting.md](troubleshooting.md#build-failures) |
| Pods stuck in `Pending` | `kubectl describe pod <name> -n product-app` | [troubleshooting.md](troubleshooting.md#pods-stuck-in-pending) |
| Backend `CrashLoopBackOff` | `kubectl logs deployment/backend -n product-app` | [troubleshooting.md](troubleshooting.md#crashloopbackoff) |
| Trivy scan blocks the build | Review SARIF in Security tab | [security-scan.md](security-scan.md) |
| Need to roll back quickly | `kubectl rollout undo` commands | [rollback.md](rollback.md) |
