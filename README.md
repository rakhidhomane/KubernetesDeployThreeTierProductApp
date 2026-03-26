# Three-Tier Application Kubernetes Deployment

[![Kubernetes Security Scan](https://github.com/rakhidhomane/KubernetesDeployThreeTierProductApp/actions/workflows/k8s-security-scan.yml/badge.svg)](https://github.com/rakhidhomane/KubernetesDeployThreeTierProductApp/actions/workflows/k8s-security-scan.yml)
[![YAML & API Version Check](https://github.com/rakhidhomane/KubernetesDeployThreeTierProductApp/actions/workflows/CkeckingVersion.yml/badge.svg)](https://github.com/rakhidhomane/KubernetesDeployThreeTierProductApp/actions/workflows/CkeckingVersion.yml)

This repository contains everything you need to deploy and operate a
three-tier product application on Kubernetes, including:

- **Kubernetes manifests** — database, backend, and frontend layers
- **IaC (Terraform)** — sample EKS cluster definition in [`iac/terraform/`](iac/terraform/)
- **CI/CD runbooks** — step-by-step guides in [`runbooks/`](runbooks/)
- **Security policies** — OPA rules, Checkov config, and Trivy integration in [`security/`](security/)

> **GitHub Codespaces**: open this repo in a Codespace and all required tools
> (`kubectl`, `terraform`, `trivy`, `kubesec`, `checkov`) are installed
> automatically via `.devcontainer/`.

---

## Repository layout

```
.
├── .devcontainer/          # Codespace configuration (tools, extensions)
├── .github/workflows/      # CI/CD GitHub Actions workflows
├── backend/                # Spring Boot backend manifests
├── database/               # MySQL manifests (PV, PVC, Secret, ConfigMap, Deployment)
├── frontend/               # React/Nginx frontend manifests
├── iac/terraform/          # Terraform IaC for EKS cluster provisioning
├── ingress/                # Kubernetes Ingress resource
├── networkpolicy/          # Network policies (default-deny + allow rules)
├── runbooks/               # CI/CD and operational runbooks
├── security/               # OPA policies, Checkov config, security policy doc
├── deploy.sh               # Automated deployment script
├── .trivyignore            # Trivy suppression list
└── .yamllint.yaml          # YAML lint configuration
```

---

## Open in GitHub Codespaces

Click the button below (or use the **Code → Open with Codespaces** menu):

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/rakhidhomane/KubernetesDeployThreeTierProductApp)

The Codespace will automatically install:

| Tool | Purpose |
|------|---------|
| `kubectl` | Kubernetes CLI |
| `helm` | Helm package manager |
| `terraform` | IaC CLI |
| `trivy` | Container & IaC security scanner |
| `kubesec` | Kubernetes security scorer |
| `opa` | Open Policy Agent |
| `checkov` | IaC security scanner |
| `yamllint` | YAML syntax linter |

---

## Application architecture

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

---

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

## IaC — Terraform (EKS cluster)

The [`iac/terraform/`](iac/terraform/) directory contains a sample Terraform
configuration that provisions an EKS cluster suitable for running this
application.

```bash
cd iac/terraform
terraform init
terraform plan -var="cluster_name=product-app-dev"
terraform apply -var="cluster_name=product-app-dev"
```

See [`iac/terraform/README.md`](iac/terraform/README.md) for full instructions.

---

## CI/CD pipeline

GitHub Actions workflows run automatically on every push / PR to `main`:

| Workflow | What it does |
|----------|-------------|
| `CkeckingVersion.yml` | YAML lint + deprecated Kubernetes API check |
| `k8s-security-scan.yml` | Trivy misconfiguration scan + kubesec scoring |

Results from Trivy appear in the **Security → Code scanning** tab.

### Run the pipeline checks locally

```bash
# YAML lint
yamllint -c .yamllint.yaml <file>

# Security scan
trivy config . --severity HIGH,CRITICAL --trivyignores .trivyignore

# kubesec
kubesec scan backend/backend-deployment.yaml
```

Full instructions → [runbooks/build-and-test.md](runbooks/build-and-test.md)

---

## Security policies

| Tool | Config | Purpose |
|------|--------|---------|
| Trivy | `.trivyignore` | IaC misconfiguration scanning (CI) |
| kubesec | inline | Deployment security scoring (CI) |
| OPA | `security/opa-policies/kubernetes.rego` | Custom Rego policies |
| Checkov | `security/checkov/.checkov.yaml` | IaC static analysis |

See [`security/SECURITY-POLICY.md`](security/SECURITY-POLICY.md) for the
full security policy and accepted risk register.

---

## Troubleshooting

### Quick diagnosis commands

```bash
kubectl get pods -n product-app
kubectl describe pod <pod-name> -n product-app
kubectl logs -n product-app deployment/backend
kubectl logs -n product-app deployment/frontend
kubectl logs -n product-app deployment/mysql
```

### Common issues

| Problem | Fix |
|---------|-----|
| Pod stuck in `Pending` | Check node resources / PVC binding |
| `CrashLoopBackOff` | Check pod logs (`--previous` flag) |
| Backend can't reach MySQL | Verify MySQL pod is running; check DNS |
| Frontend blank page | Check nginx config in `frontend-configmap.yaml` |
| Build workflow fails | See [runbooks/troubleshooting.md](runbooks/troubleshooting.md) |

**Full troubleshooting guide** → [runbooks/troubleshooting.md](runbooks/troubleshooting.md)

### Restart deployments after config change

```bash
kubectl rollout restart deployment/backend  -n product-app
kubectl rollout restart deployment/frontend -n product-app
```

### Rollback

```bash
kubectl rollout undo deployment/backend -n product-app
```

Full rollback runbook → [runbooks/rollback.md](runbooks/rollback.md)

---

## Runbooks

| Runbook | Description |
|---------|-------------|
| [pipeline-overview.md](runbooks/pipeline-overview.md) | CI/CD pipeline architecture |
| [build-and-test.md](runbooks/build-and-test.md) | Local build and test commands |
| [deploy.md](runbooks/deploy.md) | Deployment procedures |
| [troubleshooting.md](runbooks/troubleshooting.md) | Common failures and fixes |
| [rollback.md](runbooks/rollback.md) | Rollback procedures |
| [security-scan.md](runbooks/security-scan.md) | Running and interpreting security scans |

---

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
