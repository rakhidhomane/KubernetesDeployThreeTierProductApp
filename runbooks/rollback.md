# Rollback Runbook

Use this runbook when a deployment introduces a regression and you need to
restore the previous state quickly.

---

## Kubernetes native rollback

Kubernetes tracks the history of Deployments.  To roll back:

```bash
# Check rollout history
kubectl rollout history deployment/backend  -n product-app
kubectl rollout history deployment/frontend -n product-app
kubectl rollout history deployment/mysql    -n product-app

# Roll back to previous revision
kubectl rollout undo deployment/backend  -n product-app
kubectl rollout undo deployment/frontend -n product-app

# Roll back to a specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n product-app

# Watch the rollback progress
kubectl rollout status deployment/backend -n product-app
```

---

## Verify rollback

```bash
kubectl get pods -n product-app
kubectl describe deployment backend -n product-app | grep -A5 "Containers:"
```

---

## Roll back a ConfigMap or Secret change

ConfigMaps and Secrets are not versioned by Kubernetes.  To roll back a
config change:

1. Find the old value in Git:
   ```bash
   git log --oneline backend/backend-configmap.yaml
   git show <commit-hash>:backend/backend-configmap.yaml
   ```
2. Re-apply the old version:
   ```bash
   git checkout <commit-hash> -- backend/backend-configmap.yaml
   kubectl apply -f backend/backend-configmap.yaml
   kubectl rollout restart deployment/backend -n product-app
   ```
3. Commit the revert:
   ```bash
   git revert <commit-hash>
   git push
   ```

---

## Full namespace teardown and redeploy

If all else fails:

```bash
# Tear down
kubectl delete namespace product-app

# Wait for namespace to terminate
kubectl wait --for=delete namespace/product-app --timeout=60s

# Redeploy from last known-good commit
git checkout <good-commit>
./deploy.sh
```

---

## Checklist after rollback

- [ ] All pods show `Running` status
- [ ] Frontend is accessible (port-forward or NodePort)
- [ ] Backend `/api/products` returns HTTP 200
- [ ] MySQL pod logs show no errors
- [ ] Post a message to the team channel documenting what happened
- [ ] Open a post-incident ticket to track the root cause fix
