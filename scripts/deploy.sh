#!/bin/bash

# deploy.sh - Deployment automation script
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
    print_success "Loaded environment variables from .env"
else
    print_warning "No .env file found. Using defaults."
fi

echo "========================================="
echo "Deploying to: $ENVIRONMENT"
echo "========================================="

# Step 1: Build Docker image
print_info "Building Docker image..."
cd "$PROJECT_ROOT/app"
IMAGE_TAG=$(git rev-parse --short HEAD || echo "latest")
docker build -t ${APP_NAME:-devops-app}:${IMAGE_TAG} .
print_success "Docker image built: ${APP_NAME:-devops-app}:${IMAGE_TAG}"

# Step 2: Login to ECR
print_info "Logging into AWS ECR..."
aws ecr get-login-password --region ${AWS_REGION:-us-east-1} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}
print_success "Logged into ECR"

# Step 3: Tag and push image
print_info "Pushing image to ECR..."
docker tag ${APP_NAME:-devops-app}:${IMAGE_TAG} ${ECR_REGISTRY}/${APP_NAME:-devops-app}:${IMAGE_TAG}
docker tag ${APP_NAME:-devops-app}:${IMAGE_TAG} ${ECR_REGISTRY}/${APP_NAME:-devops-app}:latest
docker push ${ECR_REGISTRY}/${APP_NAME:-devops-app}:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${APP_NAME:-devops-app}:latest
print_success "Image pushed to ECR"

# Step 4: Update kubeconfig
print_info "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --region ${AWS_REGION:-us-east-1} --name ${CLUSTER_NAME:-dev-eks-cluster}
print_success "Kubeconfig updated"

# Step 5: Create Kubernetes secrets
print_info "Creating Kubernetes secrets..."
kubectl create secret generic db-credentials \
    --from-literal=username=${DB_USERNAME} \
    --from-literal=password=${DB_PASSWORD} \
    --dry-run=client -o yaml | kubectl apply -f -
print_success "Secrets created"

# Step 6: Apply Kubernetes manifests
print_info "Deploying application to Kubernetes..."
cd "$PROJECT_ROOT/kubernetes"

# Replace environment variables in manifests
export IMAGE_TAG
export ECR_REGISTRY
export DB_HOST
envsubst < deployments/app-deployment.yml | kubectl apply -f -
kubectl apply -f services/app-service.yml
kubectl apply -f configmaps/app-config.yml
kubectl apply -f autoscaling/hpa.yml

print_success "Application deployed to Kubernetes"

# Step 7: Wait for deployment
print_info "Waiting for deployment to be ready..."
kubectl rollout status deployment/devops-app-deployment --timeout=5m
print_success "Deployment is ready"

# Step 8: Get service information
print_info "Getting service information..."
kubectl get services devops-app-service
echo ""
LOAD_BALANCER=$(kubectl get service devops-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -n "$LOAD_BALANCER" ]; then
    print_success "Application is accessible at: http://$LOAD_BALANCER"
else
    print_warning "Load balancer is still provisioning. Check status with: kubectl get svc"
fi

echo ""
echo "========================================="
print_success "Deployment completed successfully! 🎉"
echo "========================================="
echo ""
echo "Useful commands:"
echo "  kubectl get pods                    - View running pods"
echo "  kubectl logs -f deployment/devops-app-deployment - View logs"
echo "  kubectl get svc                     - View services"
echo "  kubectl describe deployment devops-app-deployment - Deployment details"
