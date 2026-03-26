# Deployment Runbook

Step-by-step instructions for deploying the three-tier application to a
Kubernetes cluster.

---

## Prerequisites

- `kubectl` configured to point to your cluster (`kubectl cluster-info`)
- `helm` (if using Helm charts in future)
- Cluster has the `product-app` namespace available (created by `deploy.sh`)

---

## Deployment — automated (recommended)

```bash
chmod +x deploy.sh
./deploy.sh
```

`deploy.sh` performs the following steps in order:

1. Creates the `product-app` namespace
2. Deploys the MySQL database (PV → PVC → Secret → ConfigMap → Deployment → Service)
3. Waits for MySQL to be ready (up to 120 s)
4. Deploys the backend (Secret → ConfigMap → Deployment → Service)
5. Waits for the backend to be ready (up to 180 s)
6. Deploys the frontend (ConfigMap → Deployment → Service)
7. Prints the access URL

---

## Deployment — manual (step-by-step)

If you prefer applying resources individually:

```bash
# 1. Namespace
kubectl apply -f namespace.yaml

# 2. Database
kubectl apply -f database/mysql-pv.yaml
kubectl apply -f database/mysql-pvc.yaml
kubectl apply -f database/mysql-secret.yaml
kubectl apply -f database/mysql-configmap.yaml
kubectl apply -f database/mysql-deployment.yaml
kubectl apply -f database/mysql-service.yaml
kubectl wait --for=condition=ready pod -l app=mysql -n product-app --timeout=120s

# 3. Backend
kubectl apply -f backend/backend-secret.yaml
kubectl apply -f backend/backend-configmap.yaml
kubectl apply -f backend/backend-deployment.yaml
kubectl apply -f backend/backend-service.yaml
kubectl wait --for=condition=ready pod -l app=backend -n product-app --timeout=180s

# 4. Frontend
kubectl apply -f frontend/frontend-configmap.yaml
kubectl apply -f frontend/frontend-deployment.yaml
kubectl apply -f frontend/frontend-service.yaml

# 5. Network policies (optional but recommended)
kubectl apply -f networkpolicy/

# 6. Ingress (optional)
kubectl apply -f ingress/
```

---

## Verify deployment

```bash
kubectl get pods -n product-app
kubectl get svc  -n product-app
```

Expected output (all pods `Running`):

```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxxxxxxxx-xxxxx     1/1     Running   0          2m
frontend-xxxxxxxxx-xxxxx    1/1     Running   0          1m
mysql-xxxxxxxxx-xxxxx       1/1     Running   0          3m
```

---

## Access the application

### NodePort (direct node access)

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Frontend: http://${NODE_IP}:30007"
```

### Port-forward (Codespace / local dev)

```bash
kubectl port-forward -n product-app svc/frontend-service 8080:80
# Access: http://localhost:8080
```

---

## Update an existing deployment

```bash
# After editing a ConfigMap or Secret:
kubectl apply -f backend/backend-configmap.yaml
kubectl rollout restart deployment/backend -n product-app

# After pushing a new container image:
kubectl set image deployment/backend backend=<new-image>:<tag> -n product-app
kubectl rollout status deployment/backend -n product-app
```

---

## Cleanup

```bash
# Remove everything in the namespace
kubectl delete namespace product-app

# Or remove resources individually
kubectl delete -f frontend/
kubectl delete -f backend/
kubectl delete -f database/
kubectl delete -f namespace.yaml
```

For rollback procedures, see [rollback.md](rollback.md).
