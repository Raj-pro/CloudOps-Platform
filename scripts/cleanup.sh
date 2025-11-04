#!/bin/bash

# cleanup.sh - Resource cleanup script
# Usage: ./cleanup.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

echo "========================================="
echo "Cleanup Script - Environment: $ENVIRONMENT"
echo "========================================="

# Confirmation prompt
read -p "Are you sure you want to delete all resources? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_warning "Cleanup cancelled"
    exit 0
fi

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

# Step 1: Delete Kubernetes resources
print_warning "Deleting Kubernetes resources..."
cd "$PROJECT_ROOT/kubernetes"
kubectl delete -f deployments/ --ignore-not-found=true
kubectl delete -f services/ --ignore-not-found=true
kubectl delete -f ingress/ --ignore-not-found=true
kubectl delete -f configmaps/ --ignore-not-found=true
kubectl delete -f autoscaling/ --ignore-not-found=true
kubectl delete secret db-credentials --ignore-not-found=true
print_success "Kubernetes resources deleted"

# Step 2: Wait for LoadBalancers to be deleted
print_warning "Waiting for LoadBalancers to be deleted (this may take a few minutes)..."
sleep 30
print_success "LoadBalancers should be deleted"

# Step 3: Destroy Terraform infrastructure
print_warning "Destroying Terraform infrastructure..."
cd "$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"
terraform destroy -auto-approve
print_success "Terraform infrastructure destroyed"

# Step 4: Clean up local Docker images (optional)
read -p "Delete local Docker images? (yes/no): " DELETE_IMAGES
if [ "$DELETE_IMAGES" == "yes" ]; then
    docker rmi ${ECR_REGISTRY}/${APP_NAME:-devops-app}:latest --force 2>/dev/null || true
    docker system prune -f
    print_success "Docker images cleaned up"
fi

echo ""
echo "========================================="
print_success "Cleanup completed!"
echo "========================================="
echo ""
print_warning "Note: Some resources may take time to fully delete (e.g., S3 buckets, RDS snapshots)"
echo "Please check AWS Console to verify all resources are deleted."
