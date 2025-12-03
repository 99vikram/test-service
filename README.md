# API Service - Complete Deployment Guide

This repository contains a complete microservices application deployment setup using Kind (Kubernetes in Docker) and Helm charts.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Accessing the Application](#accessing-the-application)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## 🎯 Overview

This project provides:
- **Terraform configuration** to create and manage a Kind Kubernetes cluster
- **Helm chart** to deploy a microservices application with 12 services
- **Automated deployment** scripts for easy setup

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

### Required Tools

1. **Docker** (v20.10+)
   ```bash
   # Check installation
   docker --version
   docker ps  # Should work without errors
   ```

2. **Kind** (Kubernetes in Docker)
   ```bash
   # macOS
   brew install kind
   
   # Linux
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   
   # Verify
   kind version
   ```

3. **kubectl** (Kubernetes CLI)
   ```bash
   # macOS
   brew install kubectl
   
   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   
   # Verify
   kubectl version --client
   ```

4. **Helm** (v3.0+)
   ```bash
   # macOS
   brew install helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   
   # Verify
   helm version
   ```

5. **Terraform** (v1.0+)
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Verify
   terraform version
   ```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kind Cluster                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Control-Plane│  │   Worker 1   │  │   Worker 2   │ │
│  │   (Ports     │  │              │  │              │ │
│  │  30000-32767)│  │              │  │              │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Helm Chart: api-service                  │  │
│  │  • Frontend (NodePort 30080)                    │  │
│  │  • Backend Services (12 microservices)          │  │
│  │  • Redis Cache                                   │  │
│  │  • Network Policies                              │  │
│  │  • HPA (optional)                               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Option 1: Automated Deployment Script

```bash
# Deploy everything (creates cluster + deploys chart)
./terraform/scripts/deploy.sh

# Deploy with dev environment
./terraform/scripts/deploy.sh ../charts/api-service/values-dev.yaml

# Deploy with prod environment
./terraform/scripts/deploy.sh ../charts/api-service/values-prod.yaml
```

### Option 2: Manual Step-by-Step

Follow the detailed steps below.

## 📝 Step-by-Step Deployment

### Step 1: Setup Kind Cluster with Terraform

1. **Navigate to terraform directory**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```
   This downloads the required providers (helm, kubernetes, null, external).

3. **Review the plan** (optional)
   ```bash
   terraform plan
   ```
   This shows what Terraform will create:
   - Kind cluster with 1 control-plane and 2 worker nodes
   - Helm release for the api-service chart

4. **Create the Kind cluster**
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

   **What happens:**
   - Creates a Kind cluster named `api-service-cluster`
   - Uses configuration from `charts/kind-config.yaml`
   - Waits for cluster nodes to be ready
   - Configures kubeconfig automatically

5. **Verify cluster is running**
   ```bash
   # Get kubeconfig
   export KUBECONFIG=$(kind get kubeconfig-path --name api-service-cluster)
   
   # Check nodes
   kubectl get nodes
   ```
   You should see 3 nodes (1 control-plane, 2 workers) in `Ready` state.

### Step 2: Deploy Application Using Helm Chart

The Helm chart is automatically deployed by Terraform. However, if you want to deploy manually or update:

#### Option A: Deploy via Terraform (Recommended)

The Helm chart is already deployed in Step 1. To update:

```bash
cd terraform

# Update with default values
terraform apply

# Update with dev values
terraform apply -var="helm_values_file=../charts/api-service/values-dev.yaml"

# Update with prod values
terraform apply -var="helm_values_file=../charts/api-service/values-prod.yaml"
```

#### Option B: Deploy Manually with Helm

1. **Set kubeconfig**
   ```bash
   export KUBECONFIG=$(kind get kubeconfig-path --name api-service-cluster)
   ```

2. **Deploy with default values**
   ```bash
   helm install api-service ../charts/api-service
   ```

3. **Deploy with environment-specific values**
   ```bash
   # Development
   helm install api-service ../charts/api-service \
     -f ../charts/api-service/values-dev.yaml
   
   # Production
   helm install api-service ../charts/api-service \
     -f ../charts/api-service/values-prod.yaml
   ```

4. **Verify deployment**
   ```bash
   # Check Helm release
   helm list
   
   # Check all pods
   kubectl get pods
   
   # Check services
   kubectl get svc
   
   # Check deployments
   kubectl get deployments
   ```

5. **Wait for all pods to be ready**
   ```bash
   kubectl wait --for=condition=ready pod --all --timeout=300s
   ```

## 🌐 Accessing the Application

### Frontend Service

The frontend is exposed via NodePort `30080`:

**Option 1: Port Forward (Recommended)**
```bash
kubectl port-forward svc/frontend-external 30080:80
```
Then open: http://localhost:30080

**Option 2: Direct NodePort Access**
```bash
# Get node IP
kubectl get nodes -o wide

# Access directly (if on same machine)
curl http://localhost:30080
```

### Service Endpoints

All services are accessible within the cluster:

```bash
# List all services
kubectl get svc

# Access a specific service (from within cluster)
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside the pod:
wget -qO- http://frontend:80
```

### Service URLs

- **Frontend**: `http://frontend:80` (internal) or `http://localhost:30080` (external)
- **Currency Service**: `currencyservice:7000`
- **Product Catalog**: `productcatalogservice:3550`
- **Cart Service**: `cartservice:7070`
- **Checkout Service**: `checkoutservice:5050`
- **Shipping Service**: `shippingservice:50051`
- **Payment Service**: `paymentservice:50051`
- **Email Service**: `emailservice:5000`
- **Recommendation Service**: `recommendationservice:8080`
- **Ad Service**: `adservice:9555`
- **Redis**: `redis-cart:6379`

## 🔍 Monitoring and Debugging

### Check Pod Status
```bash
kubectl get pods -o wide
kubectl describe pod <pod-name>
```

### View Logs
```bash
# All pods for a service
kubectl logs -l app=frontend

# Specific pod
kubectl logs <pod-name>

# Follow logs
kubectl logs -f <pod-name>
```

### Check Events
```bash
kubectl get events --sort-by='.lastTimestamp'
```

### Check Service Endpoints
```bash
kubectl get endpoints
kubectl describe svc frontend
```

### Network Policies
```bash
# List network policies
kubectl get networkpolicies

# Describe a network policy
kubectl describe networkpolicy <policy-name>
```

## 🛠️ Troubleshooting

### Cluster Creation Issues

**Problem**: Kind cluster creation fails
```bash
# Check Docker is running
docker ps

# Check for port conflicts
netstat -an | grep -E "30000|30001|30080"

# Delete existing cluster and retry
kind delete cluster --name api-service-cluster
terraform apply
```

**Problem**: Nodes not ready
```bash
# Check node status
kubectl get nodes

# Check node details
kubectl describe node <node-name>

# Check Docker resources
docker stats
```

### Pod Issues

**Problem**: Pods stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes
kubectl top pods
```

**Problem**: Pods crashing
```bash
# Check logs
kubectl logs <pod-name>

# Check previous container logs
kubectl logs <pod-name> --previous

# Check events
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Problem**: Image pull errors
```bash
# Verify image exists
docker pull <image-name>

# Check image pull secrets
kubectl get secrets

# For Kind, images need to be loaded
kind load docker-image <image-name> --name api-service-cluster
```

### Service Issues

**Problem**: Cannot access frontend
```bash
# Check service exists
kubectl get svc frontend-external

# Check endpoints
kubectl get endpoints frontend-external

# Check pods are running
kubectl get pods -l app=frontend

# Test from within cluster
kubectl run -it --rm test --image=busybox --restart=Never -- wget -qO- http://frontend:80
```

### Helm Issues

**Problem**: Helm release failed
```bash
# Check release status
helm status api-service

# View release history
helm history api-service

# Rollback if needed
helm rollback api-service

# Check values
helm get values api-service
```

## 🧹 Cleanup

### Option 1: Destroy Everything (Terraform)

```bash
cd terraform
terraform destroy
```
This will:
- Delete the Helm release
- Delete the Kind cluster
- Remove all resources

### Option 2: Destroy Script

```bash
./terraform/scripts/destroy.sh
```

### Option 3: Manual Cleanup

```bash
# Delete Helm release
helm uninstall api-service

# Delete Kind cluster
kind delete cluster --name api-service-cluster

# Clean up Docker resources (optional)
docker system prune -a
```

## 📚 Additional Resources

### Project Structure

```
test-service/
├── charts/
│   ├── api-service/          # Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml       # Default values
│   │   ├── values-dev.yaml  # Dev overrides
│   │   ├── values-prod.yaml # Prod overrides
│   │   └── templates/        # Kubernetes manifests
│   └── kind-config.yaml      # Kind cluster config
├── terraform/
│   ├── main.tf               # Main Terraform config
│   ├── variables.tf          # Variables
│   ├── outputs.tf            # Outputs
│   └── scripts/             # Helper scripts
└── README.md                 # This file
```

### Configuration Files

- **Kind Config**: `charts/kind-config.yaml` - Cluster configuration with port mappings
- **Helm Values**: `charts/api-service/values.yaml` - Default application configuration
- **Terraform Vars**: `terraform/terraform.tfvars.example` - Example Terraform variables

### Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# Get all resources
kubectl get all

# Scale a deployment
kubectl scale deployment frontend --replicas=3

# Update Helm release
helm upgrade api-service ../charts/api-service

# View Helm values
helm get values api-service

# Edit a resource
kubectl edit deployment frontend

# Execute command in pod
kubectl exec -it <pod-name> -- sh
```

## 🔐 Security Notes

- All pods run as non-root users (UID/GID 1000)
- Read-only root filesystem enabled
- All capabilities dropped
- Network policies restrict pod-to-pod communication
- Service accounts created per service

## 📊 Services Overview

| Service | Port | Type | Description |
|---------|------|------|-------------|
| frontend | 80 | NodePort | Web frontend |
| currencyservice | 7000 | ClusterIP | Currency conversion |
| productcatalogservice | 3550 | ClusterIP | Product catalog |
| checkoutservice | 5050 | ClusterIP | Checkout processing |
| shippingservice | 50051 | ClusterIP | Shipping calculation |
| cartservice | 7070 | ClusterIP | Shopping cart |
| redis-cart | 6379 | ClusterIP | Redis cache |
| emailservice | 5000 | ClusterIP | Email notifications |
| paymentservice | 50051 | ClusterIP | Payment processing |
| recommendationservice | 8080 | ClusterIP | Product recommendations |
| adservice | 9555 | ClusterIP | Advertisement service |
| loadgenerator | - | - | Load testing tool |

## 🎯 Next Steps

1. **Customize Configuration**: Edit `charts/api-service/values.yaml` for your needs
2. **Enable HPA**: Set `hpa.enabled: true` in values for auto-scaling
3. **Add Ingress**: Configure ingress in values for external access
4. **Monitor**: Set up monitoring with Prometheus/Grafana
5. **CI/CD**: Integrate with your CI/CD pipeline

## 📞 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review service logs: `kubectl logs <pod-name>`
3. Check Terraform/Helm documentation

---

**Happy Deploying! 🚀**

