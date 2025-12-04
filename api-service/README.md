# API Service Helm Chart

A comprehensive Helm chart for deploying the microservices demo application with all required Kubernetes resources.

## Chart Structure

```
charts/api-service/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Development environment overrides
├── values-prod.yaml        # Production environment overrides
└── templates/
    ├── _helpers.tpl        # Reusable template functions
    ├── deployment.yaml     # Deployment templates for all services
    ├── service.yaml        # Service templates (ClusterIP)
    ├── serviceaccount.yaml # ServiceAccount templates
    ├── configmap.yaml      # ConfigMap template
    ├── secret.yaml         # Secret template
    ├── hpa.yaml            # HorizontalPodAutoscaler templates
    ├── networkpolicy.yaml  # NetworkPolicy for pod isolation
    └── ingress.yaml        # Ingress template
```

## Features

- **Multi-service Support**: Deploys all microservices (frontend, backend services, redis, etc.)
- **Security Context**: Pod and container-level security contexts with non-root users
- **Resource Management**: Configurable CPU and memory requests/limits
- **Health Probes**: Liveness and readiness probes (gRPC, HTTP, TCP)
- **Horizontal Pod Autoscaling**: Optional HPA for each service
- **Network Policies**: Pod isolation with ingress/egress rules
- **ConfigMaps & Secrets**: Centralized configuration management
- **Service Accounts**: Dedicated service accounts per service
- **Ingress Support**: Optional ingress configuration
- **Environment-specific Values**: Separate values files for dev and prod

## Installation

### Default Installation

```bash
helm install api-service ./charts/api-service
```

### Development Environment

```bash
helm install api-service ./charts/api-service -f ./charts/api-service/values-dev.yaml
```

### Production Environment

```bash
helm install api-service ./charts/api-service -f ./charts/api-service/values-prod.yaml
```

## Configuration

### Key Configuration Options

- `global.imageRegistry`: Container image registry
- `global.imageTag`: Default image tag
- `services.<serviceName>.enabled`: Enable/disable individual services
- `services.<serviceName>.replicas`: Number of replicas
- `services.<serviceName>.resources`: CPU and memory limits/requests
- `services.<serviceName>.hpa.enabled`: Enable HPA for the service
- `networkPolicy.enabled`: Enable network policies
- `ingress.enabled`: Enable ingress

### Example: Customize a Service

```yaml
services:
  frontend:
    replicas: 3
    resources:
      requests:
        cpu: 200m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
    hpa:
      enabled: true
      minReplicas: 3
      maxReplicas: 10
```

## Services Included

- `currencyservice`
- `productcatalogservice`
- `checkoutservice`
- `shippingservice`
- `cartservice`
- `redis-cart`
- `emailservice`
- `paymentservice`
- `frontend`
- `recommendationservice`
- `adservice`
- `loadgenerator`

## Security Features

- Non-root user execution (UID/GID 1000)
- Read-only root filesystem
- Dropped capabilities (ALL)
- No privilege escalation
- Network policies for pod isolation
- Service accounts per service

## Network Policies

Network policies are configured to:
- Allow ingress from frontend to backend services
- Allow egress for DNS resolution
- Restrict inter-service communication based on service dependencies
- Support environment-specific policies (more permissive in dev, strict in prod)

## Horizontal Pod Autoscaling

HPA can be enabled per service with:
- CPU utilization targets
- Memory utilization targets
- Min/max replica counts
- Scaling behavior configuration

## Values Inheritance

The chart supports value inheritance:
1. Base values from `values.yaml`
2. Environment-specific overrides from `values-dev.yaml` or `values-prod.yaml`
3. Command-line overrides via `--set` flags

Example:
```bash
helm install api-service ./charts/api-service \
  -f ./charts/api-service/values-prod.yaml \
  --set services.frontend.replicas=5
```

## Upgrading

```bash
helm upgrade api-service ./charts/api-service -f ./charts/api-service/values-prod.yaml
```

## Uninstalling

```bash
helm uninstall api-service
```

