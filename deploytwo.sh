#!/bin/bash

# Three-Tier Application Deployment Script with
# NetworkPolicies + Ingress

set -e  # Exit immediately if any command fails

echo "=========================================="
echo " Deploying Secure Three-Tier Application "
echo "=========================================="

# ==========================================
# Step 1: Create Namespace
# ==========================================
echo ""
echo "Step 1: Creating namespace..."
kubectl apply -f namespace.yaml

# ==========================================
# Step 2: Apply Network Policies
# ==========================================
echo ""
echo "Step 2: Applying Network Policies..."

kubectl apply -f networkpolicy/

echo "  - Network policies applied successfully"

# ==========================================
# Step 3: Deploy MySQL (Database Layer)
# ==========================================
echo ""
echo "Step 3: Deploying MySQL Database..."

kubectl apply -f database/mysql-pv.yaml
kubectl apply -f database/mysql-pvc.yaml
kubectl apply -f database/mysql-secret.yaml
kubectl apply -f database/mysql-configmap.yaml
kubectl apply -f database/mysql-deployment.yaml
kubectl apply -f database/mysql-service.yaml

echo "  - Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n product-app --timeout=180s

# ==========================================
# Step 4: Deploy Backend (Application Layer)
# ==========================================
echo ""
echo "Step 4: Deploying Backend Application..."

kubectl apply -f backend/backend-secret.yaml
kubectl apply -f backend/backend-configmap.yaml
kubectl apply -f backend/backend-deployment.yaml
kubectl apply -f backend/backend-service.yaml

echo "  - Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n product-app --timeout=180s

# ==========================================
# Step 5: Deploy Frontend (Presentation Layer)
# ==========================================
echo ""
echo "Step 5: Deploying Frontend Application..."

kubectl apply -f frontend/frontend-configmap.yaml
kubectl apply -f frontend/frontend-deployment.yaml
kubectl apply -f frontend/frontend-service.yaml

echo "  - Waiting for Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n product-app --timeout=180s

# ==========================================
# Step 6: Deploy Ingress
# ==========================================
echo ""
echo "Step 6: Deploying Ingress..."

kubectl apply -f ingress/product-app-ingress.yaml

echo "  - Waiting for Ingress to get external IP..."
sleep 10

# ==========================================
# Step 7: Display Status
# ==========================================
echo ""
echo "=========================================="
echo " Deployment Complete! "
echo "=========================================="

echo ""
echo "Pods:"
kubectl get pods -n product-app

echo ""
echo "Services:"
kubectl get svc -n product-app

echo ""
echo "Ingress:"
kubectl get ingress -n product-app

echo ""
echo "=========================================="
echo " Access Information "
echo "=========================================="

echo ""
echo "If using NGINX Ingress Controller:"
echo "  Access via LoadBalancer/NodePort assigned to ingress controller"

echo ""
echo "To check ingress details:"
echo "  kubectl describe ingress product-app-ingress -n product-app"

echo ""
echo "To check logs:"
echo "  Backend:  kubectl logs -n product-app deployment/backend"
echo "  Frontend: kubectl logs -n product-app deployment/frontend"
echo "  MySQL:    kubectl logs -n product-app deployment/mysql"

echo ""
echo "Deployment Finished Successfully 🚀"
