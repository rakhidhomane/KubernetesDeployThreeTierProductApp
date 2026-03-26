# Build and Test Runbook

This runbook covers how to validate Kubernetes manifests and run all checks
locally before pushing.

---

## Prerequisites (inside Codespace)

All tools are pre-installed by `.devcontainer/on-create.sh`.

```bash
yamllint  --version
trivy     --version
kubesec   version
checkov   --version
terraform --version
```

---

## 1. YAML syntax validation

```bash
# Validate all YAML files except those in .github/
find . \( -name "*.yaml" -o -name "*.yml" \) | grep -v ".github" | while IFS= read -r file; do
  echo "Checking: $file"
  yamllint -c .yamllint.yaml "$file"
done
echo "✅ YAML validation complete"
```

Configuration: [`.yamllint.yaml`](../.yamllint.yaml)

---

## 2. Kubernetes API version check

```bash
# Install pluto (if not already installed)
PLUTO_VERSION="5.19.3"
curl -sSL "https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO_VERSION}/pluto_${PLUTO_VERSION}_linux_amd64.tar.gz" \
  -o /tmp/pluto.tar.gz
tar -xzf /tmp/pluto.tar.gz -C /tmp
sudo mv /tmp/pluto /usr/local/bin/pluto

# Detect deprecated/removed API versions
pluto detect-files -d .
pluto detect-files -d . --only-show-removed
echo "✅ API version check complete"
```

---

## 3. Kubernetes manifest security scan (Trivy)

```bash
trivy config . \
  --severity HIGH,CRITICAL \
  --trivyignores .trivyignore \
  --format table
echo "✅ Trivy scan complete"
```

---

## 4. Kubernetes deployment security scoring (kubesec)

```bash
for manifest in backend/backend-deployment.yaml \
                frontend/frontend-deployment.yaml \
                database/mysql-deployment.yaml; do
  echo "--- $manifest ---"
  kubesec scan "$manifest"
done
echo "✅ kubesec scan complete"
```

---

## 5. IaC security scan (Checkov)

```bash
# Scan Terraform IaC
checkov -d iac/terraform --framework terraform --compact

# Scan Kubernetes manifests
checkov -d . --framework kubernetes --compact
echo "✅ Checkov scan complete"
```

---

## 6. Run all checks at once

```bash
bash -e <<'EOF'
echo "== YAML lint =="
find . \( -name "*.yaml" -o -name "*.yml" \) | grep -v ".github" | \
  xargs -I{} yamllint -c .yamllint.yaml {}

echo "== Trivy config scan =="
trivy config . --severity HIGH,CRITICAL --trivyignores .trivyignore --format table

echo "== kubesec scan =="
for f in backend/backend-deployment.yaml frontend/frontend-deployment.yaml database/mysql-deployment.yaml; do
  kubesec scan "$f"
done

echo "== Checkov IaC scan =="
checkov -d iac/terraform --framework terraform --compact --quiet

echo "All checks passed ✅"
EOF
```

---

## Interpreting results

| Tool | Output | Pass condition |
|------|--------|---------------|
| `yamllint` | Prints errors in `file:line:col` format | Zero errors |
| `pluto` | Table of deprecated APIs | No rows in output |
| `trivy` | Table of misconfigurations | Findings acknowledged in `.trivyignore` |
| `kubesec` | JSON with score | Score ≥ 0 |
| `checkov` | Passed / failed checks | No new CRITICAL failures |

For CI failure details, see [troubleshooting.md](troubleshooting.md).
