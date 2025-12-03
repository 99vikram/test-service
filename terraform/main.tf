terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

# Create Kind cluster
resource "null_resource" "kind_cluster" {
  triggers = {
    config_file  = filemd5(var.kind_config_path)
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Check if kind is installed
      if ! command -v kind &> /dev/null; then
        echo "Error: kind is not installed. Please install it first."
        echo "Installation: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        exit 1
      fi

      # Check if cluster already exists
      if kind get clusters | grep -q "^${var.cluster_name}$"; then
        echo "Cluster ${var.cluster_name} already exists. Skipping creation."
      else
        echo "Creating Kind cluster ${var.cluster_name}..."
        kind create cluster \
          --name ${var.cluster_name} \
          --config ${var.kind_config_path} \
          --wait 300s
        echo "Kind cluster ${var.cluster_name} created successfully."
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      if kind get clusters | grep -q "^${self.triggers.cluster_name}$"; then
        echo "Destroying Kind cluster ${self.triggers.cluster_name}..."
        kind delete cluster --name ${self.triggers.cluster_name}
        echo "Kind cluster ${self.triggers.cluster_name} destroyed."
      fi
    EOT
  }
}

# Wait for cluster to be ready
resource "null_resource" "wait_for_cluster" {
  count = var.wait_for_cluster ? 1 : 0

  depends_on = [null_resource.kind_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cluster ${var.cluster_name} to be ready..."
      
      # Export kubeconfig
      export KUBECONFIG=$(kind get kubeconfig-path --name ${var.cluster_name})
      
      # Wait for nodes to be ready
      timeout=300
      elapsed=0
      while [ $elapsed -lt $timeout ]; do
        if kubectl get nodes --no-headers 2>/dev/null | grep -q " Ready "; then
          echo "Cluster is ready!"
          kubectl get nodes
          exit 0
        fi
        echo "Waiting for nodes to be ready... ($elapsed/$timeout seconds)"
        sleep 5
        elapsed=$((elapsed + 5))
      done
      
      echo "Timeout waiting for cluster to be ready"
      exit 1
    EOT
  }
}

# Configure Kubernetes provider
data "external" "kubeconfig" {
  depends_on = [null_resource.kind_cluster]
  program    = ["sh", "-c", "echo '{\"kubeconfig\":\"'$(kind get kubeconfig-path --name ${var.cluster_name})'\"}'"]
}

provider "kubernetes" {
  config_path = data.external.kubeconfig.result.kubeconfig
}

provider "helm" {
  # Helm provider v2 automatically uses the kubernetes provider configuration
}

# Create namespace if needed
resource "kubernetes_namespace" "api_service" {
  count      = var.helm_namespace != "default" ? 1 : 0
  depends_on = [null_resource.wait_for_cluster]

  metadata {
    name = var.helm_namespace
  }
}

# Deploy Helm chart
resource "helm_release" "api_service" {
  depends_on = [
    null_resource.wait_for_cluster,
    kubernetes_namespace.api_service
  ]

  name             = var.helm_release_name
  namespace        = var.helm_namespace
  chart            = var.helm_chart_path
  wait             = true
  timeout          = 600
  create_namespace = var.helm_namespace != "default"

  # Use values file if provided
  values = var.helm_values_file != "" ? [file(var.helm_values_file)] : []

  # Wait for all resources to be ready
  wait_for_jobs = true
}


