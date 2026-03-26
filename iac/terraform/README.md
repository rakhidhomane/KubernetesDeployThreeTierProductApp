# IaC — Terraform Sample: EKS Cluster for Three-Tier App

This directory contains a sample **Terraform** configuration that provisions an
[Amazon EKS](https://aws.amazon.com/eks/) cluster suitable for running the
three-tier product application.

> **Purpose:** Demonstrate how the Kubernetes manifests in this repository map
> to real cloud infrastructure.  The Terraform code here is a *reference
> implementation* — adjust variables and backend configuration before applying
> it to a real AWS account.

---

## Directory layout

```
iac/terraform/
├── main.tf          # Root module — wires all sub-modules together
├── variables.tf     # Input variables
├── outputs.tf       # Exported values (cluster endpoint, kubeconfig, …)
├── versions.tf      # Required providers & Terraform version
└── README.md        # This file
```

---

## Prerequisites

| Tool | Min version |
|------|------------|
| Terraform | 1.5+ |
| AWS CLI | 2.x |
| kubectl | 1.28+ |

Install them inside the Codespace (already configured in `.devcontainer/`):

```bash
terraform version
aws --version
kubectl version --client
```

---

## Quick start (inside Codespace)

```bash
# 1. Authenticate to AWS
aws configure          # or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

# 2. Initialise Terraform
cd iac/terraform
terraform init

# 3. Preview changes
terraform plan -var="cluster_name=product-app-dev"

# 4. Apply (creates EKS cluster — takes ~15 min)
terraform apply -var="cluster_name=product-app-dev"

# 5. Configure kubectl
aws eks update-kubeconfig \
  --region $(terraform output -raw region) \
  --name   $(terraform output -raw cluster_name)

# 6. Deploy the application
cd ../../
./deploy.sh
```

---

## Running security checks locally

```bash
# Checkov — static IaC security scanner
checkov -d iac/terraform --framework terraform

# Trivy — misconfiguration scanner
trivy config iac/terraform
```

---

## Tear-down

```bash
# Remove the application first
kubectl delete namespace product-app

# Destroy infrastructure
cd iac/terraform
terraform destroy
```
