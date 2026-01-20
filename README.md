# Three-Tier Application Kubernetes Deployment

This directory contains Kubernetes manifests for deploying a three-tier application:
- **Database Layer**: MySQL 8.0
- **Backend Layer**: Spring Boot Application
- **Frontend Layer**: React Application with Nginx

## Quick Start

### Option 1: Using the deployment script
```bash
cd 26074_Product_ThreeTierApplication_Kubernetes
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Manual deployment (see deploy-commands.txt)
Follow the commands in `deploy-commands.txt` in order.

## Deployment Order

1. **Namespace** - Create the namespace first
2. **MySQL** - Database must be ready before backend starts
3. **Backend** - Application layer that connects to MySQL
4. **Frontend** - UI layer that connects to backend via API

## Architecture

```
┌─────────────────┐
│   Frontend      │ (NodePort: 30007)
│   (Nginx)       │
└────────┬────────┘
         │ /api/*
         ▼
┌─────────────────┐
│   Backend       │ (ClusterIP: 8080)
│   (Spring Boot) │
└────────┬────────┘
         │ JDBC
         ▼
┌─────────────────┐
│   MySQL         │ (ClusterIP: 3306)
│   Database      │
└─────────────────┘
```

## Configuration Files

### Database Layer
- `database/mysql-secret.yaml` - MySQL root password and database name
- `database/mysql-configmap.yaml` - MySQL configuration
- `database/mysql-deployment.yaml` - MySQL pod deployment
- `database/mysql-service.yaml` - MySQL service (ClusterIP)

### Backend Layer
- `backend/backend-secret.yaml` - Database credentials for backend
- `backend/backend-configmap.yaml` - Spring Boot configuration
- `backend/backend-deployment.yaml` - Backend pod deployment
- `backend/backend-service.yaml` - Backend service (ClusterIP)

### Frontend Layer
- `frontend/frontend-configmap.yaml` - Nginx configuration with API proxy
- `frontend/frontend-deployment.yaml` - Frontend pod deployment
- `frontend/frontend-service.yaml` - Frontend service (NodePort: 30007)

## Accessing the Application

### Frontend
- **NodePort**: `http://<NODE_IP>:30007`
- **Port Forward**: `kubectl port-forward -n product-app svc/frontend-service 8080:80`
  - Then access: `http://localhost:8080`

### Backend API
- **Port Forward**: `kubectl port-forward -n product-app svc/backend-service 8080:8080`
  - Then access: `http://localhost:8080/api/products`

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n product-app
```

### Check Pod Logs
```bash
# Backend logs
kubectl logs -n product-app deployment/backend

# Frontend logs
kubectl logs -n product-app deployment/frontend

# MySQL logs
kubectl logs -n product-app deployment/mysql
```

### Check Pod Details
```bash
kubectl describe pod <pod-name> -n product-app
```

### Check Services
```bash
kubectl get svc -n product-app
```

### Check ConfigMaps
```bash
kubectl get configmap -n product-app
kubectl describe configmap backend-config -n product-app
```

### Restart Deployments
```bash
# After changing ConfigMaps/Secrets
kubectl rollout restart deployment/backend -n product-app
kubectl rollout restart deployment/frontend -n product-app
```

## Common Issues

### Backend can't connect to MySQL
- Ensure MySQL pod is running: `kubectl get pods -n product-app -l app=mysql`
- Check MySQL logs: `kubectl logs -n product-app deployment/mysql`
- Verify backend ConfigMap has correct MySQL service URL

### Frontend can't connect to Backend
- Ensure backend pod is running: `kubectl get pods -n product-app -l app=backend`
- Check backend logs: `kubectl logs -n product-app deployment/backend`
- Verify frontend ConfigMap has correct backend service URL

### Mixed Content Error (HTTPS/HTTP)
- This is fixed in the frontend code - API calls use relative paths
- Ensure frontend ConfigMap nginx config proxies `/api/` correctly

## Cleanup

To remove all resources:
```bash
kubectl delete namespace product-app
```

Or delete individually:
```bash
kubectl delete -f frontend/
kubectl delete -f backend/
kubectl delete -f database/
kubectl delete -f namespace.yaml
```
