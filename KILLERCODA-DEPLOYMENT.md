# Killercoda Deployment Guide - Three-Tier Application

## Quick Deployment Commands

Copy and paste these commands in order on Killercoda:

```bash
# Navigate to the Kubernetes directory
cd 26074_Product_ThreeTierApplication_Kubernetes

# Step 1: Create Namespace
kubectl apply -f namespace.yaml

# Step 2: Deploy MySQL Database
kubectl apply -f database/mysql-secret.yaml
kubectl apply -f database/mysql-configmap.yaml
kubectl apply -f database/mysql-deployment.yaml
kubectl apply -f database/mysql-service.yaml

# Wait for MySQL to be ready (IMPORTANT!)
echo "Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n product-app --timeout=120s

# Step 3: Deploy Backend
kubectl apply -f backend/backend-secret.yaml
kubectl apply -f backend/backend-configmap.yaml
kubectl apply -f backend/backend-deployment.yaml
kubectl apply -f backend/backend-service.yaml

# Wait for Backend to be ready
echo "Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n product-app --timeout=180s

# Step 4: Deploy Frontend
kubectl apply -f frontend/frontend-configmap.yaml
kubectl apply -f frontend/frontend-deployment.yaml
kubectl apply -f frontend/frontend-service.yaml

# Wait for Frontend to be ready
echo "Waiting for Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n product-app --timeout=120s

# Step 5: Check Status
echo ""
echo "=== Pod Status ==="
kubectl get pods -n product-app

echo ""
echo "=== Service Status ==="
kubectl get svc -n product-app

echo ""
echo "=== Deployment Complete! ==="
```

## Access the Application

### Option 1: Using NodePort (if available)
```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Frontend URL: http://${NODE_IP}:30007"
```

### Option 2: Using Port Forward
```bash
# In one terminal - Forward frontend
kubectl port-forward -n product-app svc/frontend-service 8080:80

# Access at: http://localhost:8080
```

## Troubleshooting

### Check if pods are running
```bash
kubectl get pods -n product-app
```

### Check pod logs
```bash
# Backend logs
kubectl logs -n product-app deployment/backend

# Frontend logs  
kubectl logs -n product-app deployment/frontend

# MySQL logs
kubectl logs -n product-app deployment/mysql
```

### Check pod details (if pod is not running)
```bash
kubectl describe pod <pod-name> -n product-app
```

### Check if services are created
```bash
kubectl get svc -n product-app
```

### Test backend API directly
```bash
# Port forward backend
kubectl port-forward -n product-app svc/backend-service 8081:8080

# Test in another terminal
curl http://localhost:8081/api/products
```

### Restart deployments (after config changes)
```bash
kubectl rollout restart deployment/backend -n product-app
kubectl rollout restart deployment/frontend -n product-app
```

## Common Issues and Solutions

### Issue: Backend pod keeps restarting
**Solution:**
```bash
# Check backend logs
kubectl logs -n product-app deployment/backend

# Common causes:
# 1. MySQL not ready - wait for MySQL pod to be running
# 2. Wrong database credentials - check backend-secret.yaml
# 3. Wrong database URL - check backend-configmap.yaml
```

### Issue: Frontend shows "Network Error" or "Mixed Content"
**Solution:**
- This should be fixed in the code (ApiService.js uses relative paths)
- Verify frontend-configmap.yaml has correct nginx proxy configuration
- Check frontend logs: `kubectl logs -n product-app deployment/frontend`

### Issue: MySQL pod not starting
**Solution:**
```bash
# Check MySQL logs
kubectl logs -n product-app deployment/mysql

# Check if secret exists
kubectl get secret mysql-secret -n product-app

# Verify MySQL deployment
kubectl describe deployment mysql -n product-app
```

### Issue: Cannot access frontend
**Solution:**
```bash
# Check if frontend service is NodePort
kubectl get svc frontend-service -n product-app

# Use port-forward as alternative
kubectl port-forward -n product-app svc/frontend-service 8080:80
```

## Cleanup

To remove everything:
```bash
kubectl delete namespace product-app
```

## File Structure Reference

```
26074_Product_ThreeTierApplication_Kubernetes/
├── namespace.yaml                    # Namespace definition
├── database/
│   ├── mysql-secret.yaml            # MySQL credentials
│   ├── mysql-configmap.yaml         # MySQL config
│   ├── mysql-deployment.yaml        # MySQL pod
│   └── mysql-service.yaml           # MySQL service
├── backend/
│   ├── backend-secret.yaml           # Backend DB credentials
│   ├── backend-configmap.yaml       # Spring Boot config
│   ├── backend-deployment.yaml       # Backend pod
│   └── backend-service.yaml         # Backend service
└── frontend/
    ├── frontend-configmap.yaml       # Nginx config
    ├── frontend-deployment.yaml      # Frontend pod
    └── frontend-service.yaml         # Frontend service (NodePort)
```

## Verification Checklist

After deployment, verify:

- [ ] All pods are in "Running" state: `kubectl get pods -n product-app`
- [ ] MySQL pod is ready: `kubectl get pods -n product-app -l app=mysql`
- [ ] Backend pods are ready: `kubectl get pods -n product-app -l app=backend`
- [ ] Frontend pod is ready: `kubectl get pods -n product-app -l app=frontend`
- [ ] Services are created: `kubectl get svc -n product-app`
- [ ] Backend can connect to MySQL (check backend logs)
- [ ] Frontend can reach backend (check frontend logs)
- [ ] Application is accessible via browser
