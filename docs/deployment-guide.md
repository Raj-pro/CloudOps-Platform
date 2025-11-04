# Deployment Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Manual Deployment](#manual-deployment)
3. [Automated Deployment (GitHub Actions)](#automated-deployment)
4. [Deployment Verification](#deployment-verification)
5. [Rollback Procedures](#rollback-procedures)

## Prerequisites

- Infrastructure already deployed via Terraform
- kubectl configured with EKS cluster access
- Docker image built and pushed to ECR
- Database credentials stored in AWS Secrets Manager or as K8s secrets

## Manual Deployment

### Step 1: Prepare Environment

```bash
# Load environment variables
source .env

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### Step 2: Build Application

```bash
cd app
npm install
npm run build
npm test
```

### Step 3: Build and Push Docker Image

```bash
# Set variables
IMAGE_TAG=$(git rev-parse --short HEAD)
ECR_REGISTRY="<your-account-id>.dkr.ecr.us-east-1.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Build
docker build -t devops-app:$IMAGE_TAG ./app

# Tag
docker tag devops-app:$IMAGE_TAG $ECR_REGISTRY/devops-project-app:$IMAGE_TAG
docker tag devops-app:$IMAGE_TAG $ECR_REGISTRY/devops-project-app:latest

# Push
docker push $ECR_REGISTRY/devops-project-app:$IMAGE_TAG
docker push $ECR_REGISTRY/devops-project-app:latest
```

### Step 4: Create/Update Kubernetes Secrets

```bash
# Database credentials
kubectl create secret generic db-credentials \
  --from-literal=username=$DB_USERNAME \
  --from-literal=password=$DB_PASSWORD \
  --from-literal=connection-string="postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME" \
  --dry-run=client -o yaml | kubectl apply -f -

# AWS credentials (if needed)
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=$AWS_ACCESS_KEY_ID \
  --from-literal=secret-access-key=$AWS_SECRET_ACCESS_KEY \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Step 5: Deploy ConfigMaps

```bash
cd kubernetes

# Update ConfigMap with environment-specific values
export DB_HOST="<rds-endpoint>"
envsubst < configmaps/app-config.yml | kubectl apply -f -
```

### Step 6: Deploy Application

```bash
# Update deployment with new image
export IMAGE_TAG
export ECR_REGISTRY
envsubst < deployments/app-deployment.yml | kubectl apply -f -

# Deploy service
kubectl apply -f services/app-service.yml

# Deploy ingress (optional)
kubectl apply -f ingress/app-ingress.yml

# Deploy autoscaling
kubectl apply -f autoscaling/hpa.yml
```

### Step 7: Monitor Deployment

```bash
# Watch rollout status
kubectl rollout status deployment/devops-app-deployment

# Check pods
kubectl get pods -l app=devops-app -w

# View logs
kubectl logs -f deployment/devops-app-deployment
```

### Step 8: Verify Service

```bash
# Get service details
kubectl get service devops-app-service

# Get load balancer URL
LB_URL=$(kubectl get service devops-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test endpoints
curl http://$LB_URL/health
curl http://$LB_URL/api/status
```

## Automated Deployment

### Using Deployment Script

```bash
./scripts/deploy.sh dev
```

This script will:
1. Build Docker image
2. Push to ECR
3. Update kubectl config
4. Create secrets
5. Deploy to Kubernetes
6. Wait for deployment
7. Show service status

### Using GitHub Actions

#### Push to Develop Branch (Dev Deployment)

```bash
git checkout develop
git add .
git commit -m "Feature: Add new functionality"
git push origin develop
```

This triggers:
- CI pipeline (linting, testing, security scanning)
- Automatic deployment to dev environment

#### Merge to Main (Production Deployment)

```bash
# Create PR from develop to main
# After approval and merge:
git checkout main
git pull origin main
```

This triggers:
- Full CI pipeline
- Infrastructure updates (if needed)
- Production deployment
- Smoke tests

#### Manual Deployment via GitHub Actions

1. Go to Actions tab in GitHub
2. Select "CD - Continuous Deployment"
3. Click "Run workflow"
4. Select environment (dev/staging/prod)
5. Click "Run workflow"

## Deployment Verification

### 1. Check Pod Status

```bash
kubectl get pods -l app=devops-app

# Expected output:
# NAME                                    READY   STATUS    RESTARTS   AGE
# devops-app-deployment-xxxxx-yyyyy      1/1     Running   0          2m
# devops-app-deployment-xxxxx-zzzzz      1/1     Running   0          2m
```

### 2. Check Deployment

```bash
kubectl describe deployment devops-app-deployment

# Verify:
# - Replicas: 2/2 (or your desired count)
# - Available: 2
# - Image: Correct ECR URL and tag
```

### 3. Check Service

```bash
kubectl get service devops-app-service

# Verify:
# - TYPE: LoadBalancer
# - EXTERNAL-IP: Valid AWS ALB/NLB hostname
```

### 4. Test Application Endpoints

```bash
LB_URL=$(kubectl get service devops-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Health check
curl http://$LB_URL/health
# Expected: {"status":"healthy","uptime":...}

# Ready check
curl http://$LB_URL/ready
# Expected: {"status":"ready","database":"connected",...}

# Main endpoint
curl http://$LB_URL/
# Expected: {"message":"Welcome to DevOps Application",...}

# Status endpoint
curl http://$LB_URL/api/status
# Expected: Full application status
```

### 5. Check Logs

```bash
# Application logs
kubectl logs -f deployment/devops-app-deployment

# Specific pod logs
kubectl logs <pod-name> --tail=100

# Previous instance logs (if pod restarted)
kubectl logs <pod-name> --previous
```

### 6. Check Resource Usage

```bash
kubectl top pods -l app=devops-app
kubectl top nodes
```

### 7. Run Health Check Script

```bash
./scripts/health-check.sh
```

## Rollback Procedures

### Method 1: Kubernetes Rollout Undo

```bash
# Rollback to previous version
kubectl rollout undo deployment/devops-app-deployment

# Rollback to specific revision
kubectl rollout history deployment/devops-app-deployment
kubectl rollout undo deployment/devops-app-deployment --to-revision=2

# Check rollout status
kubectl rollout status deployment/devops-app-deployment
```

### Method 2: Deploy Previous Image

```bash
# Set previous image tag
PREVIOUS_TAG="abc123"
export IMAGE_TAG=$PREVIOUS_TAG
export ECR_REGISTRY="<your-registry>"

# Redeploy
envsubst < kubernetes/deployments/app-deployment.yml | kubectl apply -f -

# Monitor
kubectl rollout status deployment/devops-app-deployment
```

### Method 3: Full Redeployment

```bash
# Delete current deployment
kubectl delete deployment devops-app-deployment

# Reapply with correct version
export IMAGE_TAG="<working-version>"
envsubst < kubernetes/deployments/app-deployment.yml | kubectl apply -f -
```

## Deployment Checklist

- [ ] Infrastructure provisioned and healthy
- [ ] Database accessible from EKS cluster
- [ ] Docker image built and pushed to ECR
- [ ] Kubernetes secrets created/updated
- [ ] ConfigMaps updated with correct values
- [ ] Deployment applied successfully
- [ ] Pods running and healthy
- [ ] Service created with external IP
- [ ] Health checks passing
- [ ] Application accessible via load balancer
- [ ] Logs showing no errors
- [ ] Monitoring dashboards updated
- [ ] Team notified of deployment

## Troubleshooting Deployments

### Pods Not Starting

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Common issues:
# - Image pull errors: Check ECR permissions
# - CrashLoopBackOff: Check application logs
# - Pending: Check node resources
```

### Service Not Accessible

```bash
kubectl get endpoints devops-app-service

# If no endpoints:
# - Check pod labels match service selector
# - Verify pods are ready and running
```

### Database Connection Errors

```bash
# Test from pod
kubectl exec -it <pod-name> -- sh
nc -zv $DB_HOST 5432

# Check security groups
# Verify RDS is in correct VPC/subnet
# Check database credentials in secret
```

## Post-Deployment Tasks

1. **Monitor application metrics** in CloudWatch
2. **Check error rates** in application logs
3. **Verify database connections** are stable
4. **Test critical user flows**
5. **Update documentation** if needed
6. **Notify stakeholders** of successful deployment
7. **Tag release** in Git


