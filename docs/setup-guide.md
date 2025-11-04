# Setup Guide

## Prerequisites Installation

### 1. Install AWS CLI

**Windows (PowerShell):**
```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**macOS:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 2. Install Terraform

**Windows (Chocolatey):**
```powershell
choco install terraform
```

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 3. Install kubectl

**Windows (Chocolatey):**
```powershell
choco install kubernetes-cli
```

**macOS:**
```bash
brew install kubectl
```

**Linux:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 4. Install Ansible

**Windows (WSL recommended):**
```bash
pip install ansible
```

**macOS/Linux:**
```bash
pip3 install ansible
```

### 5. Install Docker

- **Windows/Mac:** Download from https://www.docker.com/products/docker-desktop
- **Linux:** Follow instructions at https://docs.docker.com/engine/install/

## AWS Setup

### 1. Configure AWS Credentials

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

### 2. Create S3 Bucket for Terraform State

```bash
aws s3api create-bucket \
  --bucket terraform-state-cloudops-platform \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket terraform-state-cloudops-platform \
  --versioning-configuration Status=Enabled
```

### 3. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Project Setup

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd taerraform-project
```

### 2. Run Setup Script

**Linux/macOS:**
```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

**Windows (PowerShell):**
```powershell
# Run individual setup commands
```

### 3. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env with your values
```

### 4. Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
terraform validate
terraform plan
```

## Infrastructure Deployment

### 1. Review Terraform Plan

```bash
cd terraform/environments/dev
terraform plan -out=tfplan
```

### 2. Apply Infrastructure

```bash
terraform apply tfplan
```

This will create:
- VPC with public and private subnets
- EKS cluster with node groups
- RDS PostgreSQL database
- S3 bucket for assets
- ECR repository for Docker images
- Security groups and IAM roles

**Expected time:** 15-20 minutes

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster
kubectl get nodes
```

## Application Deployment

### 1. Build and Push Docker Image

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REGISTRY>

# Build image
cd app
docker build -t devops-app:latest .

# Tag and push
docker tag devops-app:latest <ECR_REGISTRY>/devops-project-app:latest
docker push <ECR_REGISTRY>/devops-project-app:latest
```

### 2. Deploy to Kubernetes

```bash
# Create secrets
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=<YOUR_PASSWORD>

# Deploy application
cd kubernetes
kubectl apply -f configmaps/
kubectl apply -f deployments/
kubectl apply -f services/
kubectl apply -f autoscaling/
```

### 3. Check Deployment Status

```bash
kubectl get pods
kubectl get services
kubectl logs -f deployment/devops-app-deployment
```

### 4. Get Application URL

```bash
kubectl get service devops-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## GitHub Actions Setup

### 1. Add GitHub Secrets

Go to your repository Settings → Secrets and variables → Actions

Add the following secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `ECR_REGISTRY`
- `CLUSTER_NAME`
- `DB_USERNAME`
- `DB_PASSWORD`
- `DB_HOST`

### 2. Enable GitHub Actions

Push your code to trigger the CI/CD pipeline:

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

## Verification

### 1. Run Health Check

```bash
./scripts/health-check.sh
```

### 2. Test Application

```bash
# Get load balancer URL
LB_URL=$(kubectl get service devops-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test endpoints
curl http://$LB_URL/
curl http://$LB_URL/health
curl http://$LB_URL/api/status
```

## Troubleshooting

### EKS Cluster Not Accessible

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster

# Check cluster status
aws eks describe-cluster --name dev-eks-cluster --query cluster.status
```

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Database Connection Issues

```bash
# Test database connectivity from pod
kubectl exec -it <pod-name> -- sh
nc -zv <DB_HOST> 5432
```

## Next Steps

1. **Configure monitoring:** Set up CloudWatch dashboards
2. **Set up logging:** Configure centralized logging with ELK or CloudWatch Logs
3. **Enable autoscaling:** Configure HPA and cluster autoscaler
4. **Set up SSL/TLS:** Configure ACM certificates and update ingress
5. **Implement CI/CD:** Review and customize GitHub Actions workflows

