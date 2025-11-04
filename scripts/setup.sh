#!/bin/bash

# setup.sh - Initial project setup script
# This script sets up the development environment and installs required tools

set -e

echo "========================================="
echo "DevOps Project Setup Script"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

# Check if running on Linux or macOS
if [[ "$OSTYPE" != "linux-gnu"* ]] && [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for Linux or macOS"
    exit 1
fi

# Check if AWS CLI is installed
echo "Checking for AWS CLI..."
if command -v aws &> /dev/null; then
    print_success "AWS CLI is installed ($(aws --version))"
else
    print_warning "AWS CLI is not installed. Installing..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    print_success "AWS CLI installed"
fi

# Check if Terraform is installed
echo "Checking for Terraform..."
if command -v terraform &> /dev/null; then
    print_success "Terraform is installed ($(terraform version | head -n1))"
else
    print_warning "Terraform is not installed. Please install from https://www.terraform.io/downloads"
fi

# Check if kubectl is installed
echo "Checking for kubectl..."
if command -v kubectl &> /dev/null; then
    print_success "kubectl is installed ($(kubectl version --client --short 2>/dev/null || echo 'version unknown'))"
else
    print_warning "kubectl is not installed. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    print_success "kubectl installed"
fi

# Check if Ansible is installed
echo "Checking for Ansible..."
if command -v ansible &> /dev/null; then
    print_success "Ansible is installed ($(ansible --version | head -n1))"
else
    print_warning "Ansible is not installed. Installing via pip..."
    pip3 install ansible
    print_success "Ansible installed"
fi

# Check if Docker is installed
echo "Checking for Docker..."
if command -v docker &> /dev/null; then
    print_success "Docker is installed ($(docker --version))"
else
    print_warning "Docker is not installed. Please install from https://docs.docker.com/get-docker/"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cat > .env << EOF
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=

# EKS Configuration
CLUSTER_NAME=dev-eks-cluster
EKS_VERSION=1.28

# Database Configuration
DB_NAME=appdb
DB_USERNAME=admin
DB_PASSWORD=

# Application Configuration
APP_NAME=devops-app
ENVIRONMENT=dev

# Docker Registry
ECR_REGISTRY=

# Terraform Backend
TF_STATE_BUCKET=terraform-state-devops-project
TF_STATE_KEY=infrastructure/terraform.tfstate
TF_STATE_REGION=us-east-1
EOF
    print_success ".env file created. Please update with your values."
else
    print_warning ".env file already exists"
fi

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
if terraform init; then
    print_success "Terraform initialized"
else
    print_error "Terraform initialization failed"
fi
cd ..

# Install Ansible dependencies
echo "Installing Ansible dependencies..."
if [ -f ansible/requirements.yml ]; then
    ansible-galaxy install -r ansible/requirements.yml
    print_success "Ansible dependencies installed"
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh
print_success "Scripts are now executable"

echo ""
echo "========================================="
echo "CloudOps Platform Setup Script"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Update .env file with your values"
echo "3. Review and modify terraform/variables.tf"
echo "4. Initialize infrastructure: cd terraform && terraform plan"
echo "5. Deploy infrastructure: terraform apply"
echo ""
print_success "Happy DevOps-ing! 🚀"
