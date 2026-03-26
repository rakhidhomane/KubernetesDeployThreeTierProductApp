# Troubleshooting Runbook

Use this runbook to diagnose and fix common pipeline and runtime failures.

---

## Build failures

### YAML lint error

**Symptom:** `CkeckingVersion` workflow fails with a `yamllint` error.

**Diagnosis:**
```
error: … wrong indentation: expected X but found Y
```

**Fix:**
1. Run `yamllint -c .yamllint.yaml <file>` locally to identify the line.
2. Fix the indentation or formatting issue.
3. Push the fix — the workflow will re-run automatically.

Configuration is in [`.yamllint.yaml`](../.yamllint.yaml).

---

### Deprecated Kubernetes API version

**Symptom:** `CkeckingVersion` workflow fails with a `pluto` warning.

```
NAME                         KIND         VERSION          REPLACEMENT   REMOVED   DEPRECATED
backend/backend-deployment   Deployment   extensions/v1beta1   apps/v1   true      true
```

**Fix:**
Update the `apiVersion` field in the manifest:

| Deprecated | Use instead |
|-----------|-------------|
| `extensions/v1beta1` (Deployment) | `apps/v1` |
| `extensions/v1beta1` (Ingress) | `networking.k8s.io/v1` |
| `batch/v1beta1` (CronJob) | `batch/v1` |

---

### Trivy CRITICAL finding blocks pipeline

**Symptom:** `k8s-security-scan` workflow shows a new HIGH/CRITICAL finding.

**Fix options:**

1. **Fix the root cause** (preferred): apply the Kubernetes security context
   hardening described in [security-scan.md](security-scan.md).
2. **Suppress with justification**: add the AVD ID to `.trivyignore` with a
   comment explaining the decision.

---

### kubesec negative score

**Symptom:** kubesec scan step prints `scored <negative number>`.

**Fix:** Review the `scoring.critical` section of the kubesec JSON output and
address the listed controls.  Common fixes:

```yaml
# backend/backend-deployment.yaml — add under containers[].securityContext
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

---

## Runtime failures

### Pods stuck in `Pending`

**Diagnosis:**
```bash
kubectl describe pod <pod-name> -n product-app
```

Look for `Events:` at the bottom.

| Event message | Root cause | Fix |
|--------------|-----------|-----|
| `Insufficient cpu` / `Insufficient memory` | Node resource exhaustion | Scale the node group or reduce requests |
| `0/1 nodes are available: 1 node(s) had taint` | Node taint / no toleration | Add toleration or remove taint |
| `PersistentVolumeClaim is not bound` | PVC not matched to PV | Apply `database/mysql-pv.yaml` first |

---

### `CrashLoopBackOff`

**Diagnosis:**
```bash
kubectl logs deployment/backend  -n product-app --previous
kubectl logs deployment/frontend -n product-app --previous
kubectl logs deployment/mysql    -n product-app --previous
```

Common causes:

| Service | Log message | Fix |
|---------|-------------|-----|
| Backend | `Connection refused … 3306` | MySQL not ready; wait or check MySQL pod |
| Backend | `Access denied for user` | Wrong password in `backend-secret.yaml` |
| Frontend | `nginx: [emerg] …` | Nginx config error in `frontend-configmap.yaml` |
| MySQL | `InnoDB: Unable to lock ./ibdata1` | Stale lock file; delete PVC and PV, redeploy |

---

### Backend can't connect to MySQL

```bash
# Confirm MySQL is running
kubectl get pods -n product-app -l app=mysql

# Check MySQL service DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n product-app -- \
  nslookup mysql-service
```

Expected: `mysql-service.product-app.svc.cluster.local` resolves.

---

### Frontend shows blank page / API errors

```bash
# Check the nginx config
kubectl describe configmap frontend-config -n product-app

# Test the backend from inside the cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n product-app -- \
  curl -s http://backend-service:8080/api/products
```

---

### Port-forward not working in Codespace

```bash
# Check if the pod is running
kubectl get pods -n product-app

# Re-run port-forward
kubectl port-forward -n product-app svc/frontend-service 8080:80 &
```

In the **Ports** panel of VS Code (Codespace), ensure port 8080 is listed and
visibility is set to **Public** (or **Private** for private repos).

---

## CI workflow questions

**"Why did my build fail?"**

1. Go to **Actions** tab → click the failed workflow run.
2. Expand the failed job step to read the log output.
3. Match the error message to a section in this document.
4. If the error is not covered here, open an issue and link the workflow run.

**"How can I fix a deployment error in the pipeline?"**

1. Reproduce the failure locally using the commands in
   [build-and-test.md](build-and-test.md).
2. Fix the issue and verify locally before pushing.
3. Push the fix — the workflow will re-run automatically.

**"How do I re-trigger a failed workflow without pushing?"**

In the GitHub UI: **Actions** → select workflow → **Re-run failed jobs**.
