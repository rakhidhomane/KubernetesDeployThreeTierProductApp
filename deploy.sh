#!/bin/bash

# Three-Tier Application Deployment Script for Kubernetes
# This script deploys MySQL, Backend, and Frontend in the correct order

set -e  # Exit on error

echo "=========================================="
echo "Deploying Three-Tier Application"
echo "=========================================="

# Step 1: Create namespace
echo ""
echo "Step 1: Creating namespace..."
kubectl apply -f namespace.yaml

# Step 2: Deploy MySQL Database Layer
echo ""
echo "Step 2: Deploying MySQL Database..."
echo "  - Creating MySQL Secret..."
kubectl apply -f database/mysql-secret.yaml

echo "  - Creating MySQL ConfigMap..."
kubectl apply -f database/mysql-configmap.yaml

echo "  - Deploying MySQL..."
kubectl apply -f database/mysql-deployment.yaml
kubectl apply -f database/mysql-service.yaml

# Wait for MySQL to be ready
echo "  - Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n product-app --timeout=120s

# Step 3: Deploy Backend Application Layer
echo ""
echo "Step 3: Deploying Backend Application..."
echo "  - Creating Backend Secret..."
kubectl apply -f backend/backend-secret.yaml

echo "  - Creating Backend ConfigMap..."
kubectl apply -f backend/backend-configmap.yaml

echo "  - Deploying Backend..."
kubectl apply -f backend/backend-deployment.yaml
kubectl apply -f backend/backend-service.yaml

# Wait for Backend to be ready
echo "  - Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n product-app --timeout=180s

# Step 4: Deploy Frontend Application Layer
echo ""
echo "Step 4: Deploying Frontend Application..."
echo "  - Creating Frontend ConfigMap..."
kubectl apply -f frontend/frontend-configmap.yaml

echo "  - Deploying Frontend..."
kubectl apply -f frontend/frontend-deployment.yaml
kubectl apply -f frontend/frontend-service.yaml

# Wait for Frontend to be ready
echo "  - Waiting for Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n product-app --timeout=120s

# Step 5: Display Status
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Checking pod status..."
kubectl get pods -n product-app

echo ""
echo "Checking services..."
kubectl get svc -n product-app

echo ""
echo "=========================================="
echo "Access Information:"
echo "=========================================="
echo ""
echo "Frontend URL (NodePort):"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "  http://${NODE_IP}:30007"
echo ""
echo "Or use port-forward:"
echo "  kubectl port-forward -n product-app svc/frontend-service 8080:80"
echo "  Then access: http://localhost:8080"
echo ""
echo "To check logs:"
echo "  Backend:  kubectl logs -n product-app deployment/backend"
echo "  Frontend: kubectl logs -n product-app deployment/frontend"
echo "  MySQL:    kubectl logs -n product-app deployment/mysql"
echo ""
