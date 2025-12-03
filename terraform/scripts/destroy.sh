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

echo -e "${YELLOW}=== Destroying API Service Kind Cluster ===${NC}\n"

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Get cluster name
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "api-service-cluster")

echo -e "${YELLOW}This will destroy:${NC}"
echo "  - Helm release: api-service"
echo "  - Kind cluster: $CLUSTER_NAME"
echo "  - All associated resources"
echo ""
echo -e "${RED}Are you sure you want to continue? (yes/no)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Destruction cancelled"
    exit 0
fi

# Destroy
echo -e "\n${YELLOW}Destroying resources...${NC}"
terraform destroy -auto-approve

echo -e "\n${GREEN}=== Destruction Complete ===${NC}\n"
echo "All resources have been destroyed."

