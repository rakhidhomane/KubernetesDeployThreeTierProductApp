package kubernetes

# Deny containers that run as root
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.securityContext.runAsNonRoot
  msg := sprintf(
    "Container '%v' in Deployment '%v' must set securityContext.runAsNonRoot: true",
    [container.name, input.metadata.name]
  )
}

# Deny containers that allow privilege escalation
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  container.securityContext.allowPrivilegeEscalation == true
  msg := sprintf(
    "Container '%v' in Deployment '%v' must set allowPrivilegeEscalation: false",
    [container.name, input.metadata.name]
  )
}

# Deny containers with no resource limits
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg := sprintf(
    "Container '%v' in Deployment '%v' must define resource limits",
    [container.name, input.metadata.name]
  )
}

# Deny containers using the :latest image tag
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf(
    "Container '%v' in Deployment '%v' must not use the ':latest' image tag",
    [container.name, input.metadata.name]
  )
}

# Deny Deployments not in a named namespace
deny[msg] {
  input.kind == "Deployment"
  not input.metadata.namespace
  msg := sprintf(
    "Deployment '%v' must specify a namespace",
    [input.metadata.name]
  )
}
