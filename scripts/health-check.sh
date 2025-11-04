#!/bin/bash

# health-check.sh - Application and infrastructure health check
# Usage: ./health-check.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
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
fi

print_header "CloudOps Platform Health Check"

# Check AWS connectivity
echo ""
echo "1. AWS Connectivity"
if aws sts get-caller-identity &>/dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    print_success "Connected to AWS Account: $AWS_ACCOUNT"
else
    print_error "Cannot connect to AWS. Check your credentials."
    exit 1
fi

# Check EKS cluster
echo ""
echo "2. EKS Cluster Status"
if aws eks describe-cluster --name ${CLUSTER_NAME:-dev-eks-cluster} --region ${AWS_REGION:-us-east-1} &>/dev/null; then
    CLUSTER_STATUS=$(aws eks describe-cluster --name ${CLUSTER_NAME:-dev-eks-cluster} --region ${AWS_REGION:-us-east-1} --query 'cluster.status' --output text)
    if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
        print_success "EKS Cluster is ACTIVE"
    else
        print_warning "EKS Cluster status: $CLUSTER_STATUS"
    fi
else
    print_error "EKS Cluster not found"
fi

# Check kubectl connectivity
echo ""
echo "3. Kubernetes Connectivity"
if kubectl cluster-info &>/dev/null; then
    print_success "kubectl can connect to cluster"
    K8S_VERSION=$(kubectl version --short 2>/dev/null | grep Server || echo "unknown")
    echo "   $K8S_VERSION"
else
    print_error "kubectl cannot connect to cluster"
fi

# Check nodes
echo ""
echo "4. Kubernetes Nodes"
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo 0)
if [ "$NODE_COUNT" -gt 0 ]; then
    print_success "$READY_NODES/$NODE_COUNT nodes are Ready"
    kubectl get nodes
else
    print_error "No nodes found"
fi

# Check deployments
echo ""
echo "5. Application Deployments"
if kubectl get deployment devops-app-deployment &>/dev/null; then
    DESIRED=$(kubectl get deployment devops-app-deployment -o jsonpath='{.spec.replicas}')
    READY=$(kubectl get deployment devops-app-deployment -o jsonpath='{.status.readyReplicas}')
    if [ "$DESIRED" == "$READY" ]; then
        print_success "Deployment is healthy: $READY/$DESIRED pods ready"
    else
        print_warning "Deployment status: $READY/$DESIRED pods ready"
    fi
    kubectl get deployment devops-app-deployment
else
    print_error "Deployment not found"
fi

# Check pods
echo ""
echo "6. Application Pods"
kubectl get pods -l app=devops-app 2>/dev/null || print_error "No pods found"

# Check services
echo ""
echo "7. Services"
if kubectl get service devops-app-service &>/dev/null; then
    print_success "Service is running"
    kubectl get service devops-app-service
    LOAD_BALANCER=$(kubectl get service devops-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$LOAD_BALANCER" ]; then
        print_success "Load Balancer: $LOAD_BALANCER"
    else
        print_warning "Load Balancer is still provisioning"
    fi
else
    print_error "Service not found"
fi

# Check RDS
echo ""
echo "8. RDS Database"
DB_INSTANCE="${ENVIRONMENT:-dev}-postgres"
if aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE --region ${AWS_REGION:-us-east-1} &>/dev/null; then
    DB_STATUS=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE --region ${AWS_REGION:-us-east-1} --query 'DBInstances[0].DBInstanceStatus' --output text)
    if [ "$DB_STATUS" == "available" ]; then
        print_success "RDS Database is available"
    else
        print_warning "RDS Database status: $DB_STATUS"
    fi
else
    print_error "RDS Database not found"
fi

# Check S3 bucket
echo ""
echo "9. S3 Bucket"
BUCKET_NAME="${PROJECT_NAME:-devops-project}-${ENVIRONMENT:-dev}-assets"
if aws s3 ls s3://$BUCKET_NAME &>/dev/null; then
    print_success "S3 Bucket exists: $BUCKET_NAME"
else
    print_error "S3 Bucket not found: $BUCKET_NAME"
fi

# Application endpoint health check
echo ""
echo "10. Application Health Endpoint"
if [ -n "$LOAD_BALANCER" ]; then
    if curl -f -s http://$LOAD_BALANCER/health &>/dev/null; then
        print_success "Application health endpoint is responding"
    else
        print_warning "Application health endpoint is not responding yet"
    fi
else
    print_warning "Cannot check application health - no load balancer"
fi

echo ""
print_header "Health Check Complete"
echo ""
echo "Summary:"
echo "  - Run 'kubectl get all' for complete Kubernetes status"
echo "  - Run 'kubectl logs -f deployment/devops-app-deployment' for logs"
echo "  - Run 'kubectl describe pod <pod-name>' for pod details"
