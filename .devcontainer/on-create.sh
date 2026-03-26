#!/bin/bash
# .devcontainer/on-create.sh
# Runs once when the Codespace container is first created.
set -e

echo "=== Setting up Kubernetes Three-Tier App workspace ==="

# Install Trivy for local security scanning
echo "Installing Trivy..."
TRIVY_SCRIPT_PATH="/tmp/trivy-install.sh"
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  -o "${TRIVY_SCRIPT_PATH}" 2>/dev/null && \
  chmod +x "${TRIVY_SCRIPT_PATH}" && \
  bash "${TRIVY_SCRIPT_PATH}" -b /usr/local/bin latest && \
  rm -f "${TRIVY_SCRIPT_PATH}" && \
  echo "Trivy installed" || echo "Trivy install skipped (offline or rate-limited)"

# Install kubesec
echo "Installing kubesec..."
KUBESEC_VERSION="2.14.2"
curl -sSfL "https://github.com/controlplaneio/kubesec/releases/download/v${KUBESEC_VERSION}/kubesec_linux_amd64.tar.gz" \
  -o /tmp/kubesec.tar.gz 2>/dev/null && \
  tar -xzf /tmp/kubesec.tar.gz -C /tmp kubesec && \
  mv /tmp/kubesec /usr/local/bin/kubesec && \
  echo "kubesec installed" || echo "kubesec install skipped"

# Install OPA
echo "Installing OPA..."
curl -sSfL -o /usr/local/bin/opa \
  "https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static" 2>/dev/null && \
  chmod +x /usr/local/bin/opa && \
  echo "OPA installed" || echo "OPA install skipped"

echo "=== Workspace setup complete ==="
echo ""
echo "Available tools:"
echo "  kubectl    - Kubernetes CLI"
echo "  helm       - Helm package manager"
echo "  terraform  - Infrastructure as Code"
echo "  trivy      - Container & IaC security scanner"
echo "  kubesec    - Kubernetes security scoring"
echo "  opa        - Open Policy Agent"
echo "  checkov    - IaC security scanner (install via: pip install checkov)"
echo "  yamllint   - YAML linter"
echo ""
echo "Quick start: cat README.md"
