# CloudOps Platform

A comprehensive DevOps project demonstrating infrastructure as code, configuration management, container orchestration, and CI/CD practices using modern tools.

## 🏗️ Architecture Overview

This project deploys a scalable web application on AWS EKS (Kubernetes) with the following components:

- **Terraform**: Infrastructure provisioning (VPC, EKS, RDS, S3, etc.)
- **Ansible**: Configuration management and application deployment
- **Kubernetes**: Container orchestration on AWS EKS
- **GitHub Actions**: CI/CD pipeline automation
- **Shell Scripts**: Automation utilities
- **Docker**: Application containerization


```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions CI/CD                    │
│              (Build → Test → Deploy → Monitor)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  VPC (Terraform Managed)                             │   │
│  │  ┌─────────────────┐      ┌─────────────────┐        │   │
│  │  │   EKS Cluster   │      │   RDS Database  │        │   │
│  │  │  (Kubernetes)   │◄────►│   (PostgreSQL)  │        │   │
│  │  │                 │      └─────────────────┘        │   │
│  │  │  ┌───────────┐  │                                 │   │
│  │  │  │   Pods    │  │      ┌─────────────────┐        │   │
│  │  │  │(Nginx+App)│◄─┼─────►│   S3 Bucket     │        │   │
│  │  │  └───────────┘  │      │   (Assets)      │        │   │
│  │  └─────────────────┘      └─────────────────┘        │   │
│  │           │                                          │   │
│  │           ▼                                          │   │
│  │  ┌─────────────────┐                                 │   │
│  │  │  Load Balancer  │                                 │   │
│  │  └─────────────────┘                                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
.
├── terraform/                  # Infrastructure as Code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── vpc/              # VPC, subnets, routing
│   │   ├── eks/              # EKS cluster configuration
│   │   ├── rds/              # RDS database
│   │   └── s3/               # S3 buckets
│   ├── environments/          # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── main.tf               # Root Terraform configuration
│
├── ansible/                   # Configuration Management
│   ├── playbooks/            # Ansible playbooks
│   ├── roles/                # Ansible roles
│   ├── inventory/            # Dynamic inventory
│   └── ansible.cfg           # Ansible configuration
│
├── kubernetes/                # K8s Manifests
│   ├── deployments/          # Deployment configurations
│   ├── services/             # Service definitions
│   ├── ingress/              # Ingress rules
│   ├── configmaps/           # Configuration maps
│   └── secrets/              # Secret templates
│
├── .github/                   # GitHub Actions
│   └── workflows/            # CI/CD workflows
│       ├── ci.yml            # Continuous Integration
│       ├── cd.yml            # Continuous Deployment
│       └── destroy.yml       # Infrastructure cleanup
│
├── scripts/                   # Shell Scripts
│   ├── deploy.sh             # Deployment automation
│   ├── setup.sh              # Initial setup
│   ├── cleanup.sh            # Resource cleanup
│   └── health-check.sh       # Health monitoring
│
├── app/                       # Sample Application
│   ├── src/                  # Application source code
│   ├── Dockerfile            # Container definition
│   └── package.json          # Dependencies
│
└── docs/                      # Documentation
    ├── setup-guide.md
    ├── deployment-guide.md
    └── troubleshooting.md
```

## 🚀 Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** >= 1.5.0
- **Ansible** >= 2.15
- **kubectl** >= 1.27
- **Docker** >= 24.0
- **AWS CLI** configured with credentials
- **Git** and GitHub account
- **Bash/PowerShell** for script execution

## 🔧 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd cloudops-platform
chmod +x scripts/*.sh  # Linux/Mac
./scripts/setup.sh
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region
```

### 3. Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Configure kubectl for EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster
kubectl get nodes
```

### 5. Deploy Application with Ansible

```bash
cd ansible
ansible-playbook -i inventory/aws_ec2.yml playbooks/deploy-app.yml
```

### 6. Deploy to Kubernetes

```bash
cd kubernetes
kubectl apply -f deployments/
kubectl apply -f services/
kubectl apply -f ingress/
```

## 🔐 Environment Variables

Create a `.env` file (use `.env.example` as template):

```bash
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
CLUSTER_NAME=dev-eks-cluster
DB_NAME=appdb
DB_USERNAME=admin
# Add DB_PASSWORD to GitHub Secrets
```

## 📊 GitHub Actions Workflows

### CI Pipeline (Triggered on PR)
- Linting and formatting checks
- Terraform validation
- Ansible syntax check
- Docker image build
- Security scanning

### CD Pipeline (Triggered on merge to main)
- Build and push Docker images
- Apply Terraform changes
- Deploy to Kubernetes
- Run smoke tests
- Notify on Slack/Email

## 🧪 Testing

```bash
# Terraform validation
cd terraform && terraform validate

# Ansible syntax check
ansible-playbook --syntax-check ansible/playbooks/deploy-app.yml

# Kubernetes dry-run
kubectl apply --dry-run=client -f kubernetes/deployments/

# Health check
./scripts/health-check.sh
```

## 📝 Deployment Guide

### Manual Deployment

1. **Provision Infrastructure**
   ```bash
   cd terraform/environments/prod
   terraform apply
   ```

2. **Configure Servers**
   ```bash
   cd ansible
   ansible-playbook -i inventory/aws_ec2.yml playbooks/configure-servers.yml
   ```

3. **Deploy Application**
   ```bash
   ./scripts/deploy.sh prod
   ```

### Automated Deployment (GitHub Actions)

1. Push to `develop` branch → Deploys to dev environment
2. Create PR to `main` → Runs CI checks
3. Merge to `main` → Deploys to production

## 🛠️ Useful Commands

```bash
# Check cluster status
kubectl get all -n default

# View logs
kubectl logs -f deployment/app-deployment

# Scale deployment
kubectl scale deployment/app-deployment --replicas=5

# Terraform state
terraform show
terraform state list

# Ansible ad-hoc commands
ansible all -i inventory/aws_ec2.yml -m ping
```


## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.


**CloudOps Platform - Built with ❤️ using Terraform, AWS, Ansible, Kubernetes, and GitHub Actions**
