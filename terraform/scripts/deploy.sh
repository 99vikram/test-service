#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}=== API Service Kind Cluster Deployment ===${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        echo "Please install $1 first"
        exit 1
    fi
}

check_command terraform
check_command kind
check_command kubectl
check_command helm
check_command docker

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker first"
    exit 1
fi

echo -e "${GREEN}All prerequisites met!${NC}\n"

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    terraform init
    echo -e "${GREEN}Terraform initialized!${NC}\n"
fi

# Check for custom values file
VALUES_FILE=""
if [ -n "$1" ]; then
    VALUES_FILE="$1"
    if [ ! -f "$VALUES_FILE" ]; then
        echo -e "${RED}Error: Values file not found: $VALUES_FILE${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Using values file: $VALUES_FILE${NC}\n"
fi

# Plan
echo -e "${YELLOW}Planning Terraform deployment...${NC}"
if [ -n "$VALUES_FILE" ]; then
    terraform plan -var="helm_values_file=$VALUES_FILE"
else
    terraform plan
fi

echo -e "\n${YELLOW}Do you want to apply these changes? (yes/no)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Apply
echo -e "\n${YELLOW}Applying Terraform configuration...${NC}"
if [ -n "$VALUES_FILE" ]; then
    terraform apply -var="helm_values_file=$VALUES_FILE" -auto-approve
else
    terraform apply -auto-approve
fi

# Get cluster info
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "api-service-cluster")
KUBECONFIG_PATH=$(kind get kubeconfig-path --name "$CLUSTER_NAME" 2>/dev/null || echo "")

if [ -n "$KUBECONFIG_PATH" ]; then
    export KUBECONFIG="$KUBECONFIG_PATH"
    
    echo -e "\n${GREEN}=== Deployment Complete! ===${NC}\n"
    echo -e "${GREEN}Cluster: $CLUSTER_NAME${NC}"
    echo -e "${GREEN}Kubeconfig: $KUBECONFIG_PATH${NC}\n"
    
    echo -e "${YELLOW}Cluster Status:${NC}"
    kubectl get nodes
    
    echo -e "\n${YELLOW}Helm Releases:${NC}"
    helm list
    
    echo -e "\n${YELLOW}Pods Status:${NC}"
    kubectl get pods
    
    echo -e "\n${YELLOW}Services:${NC}"
    kubectl get svc
    
    echo -e "\n${GREEN}To access the frontend service:${NC}"
    echo "  kubectl port-forward svc/frontend-external 30080:80"
    echo "  Then open http://localhost:30080 in your browser"
    echo ""
    echo -e "${GREEN}Or use NodePort directly:${NC}"
    echo "  http://localhost:30080"
else
    echo -e "${RED}Warning: Could not get kubeconfig path${NC}"
fi

