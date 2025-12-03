# Terraform Configuration for Kind Cluster and Helm Chart Deployment

This Terraform configuration creates a Kind (Kubernetes in Docker) cluster and deploys the API Service Helm chart.

## Prerequisites

1. **Terraform** (>= 1.0)
   ```bash
   # Install Terraform
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Kind** (Kubernetes in Docker)
   ```bash
   # macOS
   brew install kind
   
   # Linux
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   ```

3. **kubectl**
   ```bash
   # macOS
   brew install kubectl
   
   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   ```

4. **Helm** (>= 3.0)
   ```bash
   # macOS
   brew install helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

5. **Docker** (required for Kind)
   ```bash
   # Ensure Docker is running
   docker ps
   ```

## Directory Structure

```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf            # Output definitions
├── terraform.tfvars.example  # Example variables file
└── README.md            # This file
```

## Usage

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Review and Customize Variables (Optional)

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars to customize:
# - cluster_name
# - helm_namespace
# - helm_values_file (for dev/prod environments)
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Verify the Deployment

```bash
# Get cluster kubeconfig
export KUBECONFIG=$(kind get kubeconfig-path --name api-service-cluster)

# Check cluster nodes
kubectl get nodes

# Check Helm release
helm list

# Check all pods
kubectl get pods --all-namespaces

# Check services
kubectl get svc
```

### 6. Access the Frontend Service

The frontend service is exposed via NodePort 30080:

```bash
# Port forward to access locally
kubectl port-forward svc/frontend-external 30080:80

# Or access directly via NodePort (if on the same machine)
# http://localhost:30080
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | Name of the Kind cluster | `api-service-cluster` |
| `kind_config_path` | Path to Kind config file | `../charts/kind-config.yaml` |
| `helm_chart_path` | Path to Helm chart | `../charts/api-service` |
| `helm_release_name` | Helm release name | `api-service` |
| `helm_namespace` | Kubernetes namespace | `default` |
| `helm_values_file` | Path to values file (optional) | `""` |
| `wait_for_cluster` | Wait for cluster readiness | `true` |

## Environment-Specific Deployments

### Development Environment

```bash
terraform apply -var="helm_values_file=../charts/api-service/values-dev.yaml"
```

### Production Environment

```bash
terraform apply -var="helm_values_file=../charts/api-service/values-prod.yaml"
```

## Destroying Resources

To tear down the cluster and all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will:
- Delete the Helm release
- Delete the Kind cluster
- Clean up all resources

## Troubleshooting

### Cluster Creation Fails

1. Ensure Docker is running: `docker ps`
2. Check if port conflicts exist (Kind uses ports 30000-32767)
3. Verify Kind is installed: `kind version`

### Helm Deployment Fails

1. Check cluster connectivity: `kubectl get nodes`
2. Verify chart path is correct
3. Check Helm values for errors: `helm lint ../charts/api-service`

### Pods Not Starting

1. Check pod status: `kubectl get pods`
2. Check pod logs: `kubectl logs <pod-name>`
3. Check events: `kubectl get events --sort-by='.lastTimestamp'`

### Image Pull Errors

1. Ensure images are accessible
2. Check if image registry requires authentication
3. Verify image names in values.yaml

## Outputs

After successful deployment, Terraform outputs:

- `cluster_name`: Name of the Kind cluster
- `kubeconfig_path`: Path to kubeconfig file
- `helm_release_name`: Name of Helm release
- `helm_release_namespace`: Namespace of Helm release
- `cluster_info`: Connection instructions
- `frontend_nodeport`: NodePort for frontend service

## Advanced Usage

### Custom Namespace

```bash
terraform apply -var="helm_namespace=api-services"
```

### Custom Cluster Name

```bash
terraform apply -var="cluster_name=my-custom-cluster"
```

### Multiple Environments

```bash
# Development
terraform workspace new dev
terraform apply -var="helm_values_file=../charts/api-service/values-dev.yaml"

# Production
terraform workspace new prod
terraform apply -var="helm_values_file=../charts/api-service/values-prod.yaml"
```

## Notes

- The Kind cluster persists between Terraform runs unless explicitly destroyed
- Port mappings in kind-config.yaml expose NodePorts 30000-32767
- The frontend-external service uses NodePort 30080
- All services are deployed in the specified namespace (default: `default`)

