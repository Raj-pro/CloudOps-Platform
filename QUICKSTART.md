# Quick Start Guide (Windows)

## 🚀 Get Started in 15 Minutes

### Prerequisites Installation (Windows)

1. **Install Chocolatey** (Package Manager)
   ```powershell
   # Run PowerShell as Administrator
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

2. **Install Required Tools**
   ```powershell
   # Install all tools at once
   choco install -y terraform kubectl docker-desktop awscli git
   
   # Install Python and Ansible
   choco install -y python
   pip install ansible
   ```

3. **Restart PowerShell** to apply changes

### Quick Setup

1. **Clone the Repository**
   ```powershell
   git clone <your-repo-url>
   cd "taerraform project"
   ```

2. **Run Setup Script**
   ```powershell
   .\scripts\setup.ps1
   ```

3. **Configure AWS**
   ```powershell
   aws configure
   # Enter: Access Key, Secret Key, Region (us-east-1), Output (json)
   ```

4. **Create Backend Resources**
   ```powershell
   # Create S3 bucket for Terraform state
   aws s3api create-bucket --bucket terraform-state-cloudops-platform --region us-east-1
   
   # Create DynamoDB table for locking
   aws dynamodb create-table `
     --table-name terraform-state-lock `
     --attribute-definitions AttributeName=LockID,AttributeType=S `
     --key-schema AttributeName=LockID,KeyType=HASH `
     --billing-mode PAY_PER_REQUEST `
     --region us-east-1
   ```

5. **Configure Environment**
   ```powershell
   # Copy environment template
   Copy-Item .env.example .env
   
   # Edit .env with your values
   notepad .env
   ```

6. **Deploy Infrastructure**
   ```powershell
   cd terraform\environments\dev
   terraform init
   terraform plan
   terraform apply
   ```

   ⏱️ **This will take 15-20 minutes**

7. **Configure kubectl**
   ```powershell
   aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster
   kubectl get nodes
   ```

8. **Deploy Application**
   ```powershell
   cd ..\..\..
   
   # Get ECR registry from Terraform output
   cd terraform\environments\dev
   $ECR_REGISTRY = terraform output -raw ecr_repository_url
   cd ..\..\..
   
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
   
   # Build and push image
   cd app
   docker build -t devops-app:latest .
   docker tag devops-app:latest ${ECR_REGISTRY}:latest
   docker push ${ECR_REGISTRY}:latest
   cd ..
   
   # Deploy to Kubernetes
   kubectl create secret generic db-credentials `
     --from-literal=username=admin `
     --from-literal=password=YourPassword123!
   
   kubectl apply -f kubernetes\configmaps\
   kubectl apply -f kubernetes\deployments\
   kubectl apply -f kubernetes\services\
   kubectl apply -f kubernetes\autoscaling\
   ```

9. **Check Status**
   ```powershell
   kubectl get all
   kubectl get service devops-app-service
   ```

10. **Get Application URL**
    ```powershell
    $LB_URL = kubectl get service devops-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    Write-Host "Application URL: http://$LB_URL"
    
    # Test the application
    curl "http://$LB_URL/health"
    ```

### Common Commands (Windows)

```powershell
# Check infrastructure status
cd terraform\environments\dev
terraform output

# View Kubernetes resources
kubectl get all
kubectl get pods -w
kubectl logs -f deployment/devops-app-deployment

# Scale application
kubectl scale deployment/devops-app-deployment --replicas=5

# Update application
docker build -t devops-app:v2 .\app
docker tag devops-app:v2 ${ECR_REGISTRY}:v2
docker push ${ECR_REGISTRY}:v2
kubectl set image deployment/devops-app-deployment app=${ECR_REGISTRY}:v2

# Cleanup everything
kubectl delete -f kubernetes\ -R
cd terraform\environments\dev
terraform destroy
```

### GitHub Actions Setup

1. **Go to Repository Settings** → Secrets and variables → Actions

2. **Add Secrets**:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `ECR_REGISTRY`: Your ECR registry URL
   - `CLUSTER_NAME`: dev-eks-cluster
   - `DB_USERNAME`: admin
   - `DB_PASSWORD`: Your database password
   - `DB_HOST`: Your RDS endpoint

3. **Push to GitHub**:
   ```powershell
   git add .
   git commit -m "Initial CloudOps Platform setup"
   git push origin main
   ```

4. **Check Actions Tab** to see the CI/CD pipeline running

### Troubleshooting (Windows)

**PowerShell Execution Policy Error**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Docker Not Running**:
- Start Docker Desktop
- Wait for Docker to fully start
- Check system tray icon

**AWS CLI Not Found**:
```powershell
# Restart PowerShell or add to PATH manually
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
```

**kubectl Not Found**:
```powershell
choco install kubernetes-cli
# Restart PowerShell
```

### Video Tutorial Suggestions

1. ✅ Prerequisites installation on Windows
2. ✅ AWS account setup and configuration
3. ✅ Terraform infrastructure deployment
4. ✅ Docker image build and push
5. ✅ Kubernetes deployment
6. ✅ GitHub Actions configuration
7. ✅ Monitoring and troubleshooting

### Next Steps

- 📖 Read [Setup Guide](docs/setup-guide.md) for detailed instructions
- 📖 Read [Deployment Guide](docs/deployment-guide.md) for deployment strategies
- 🔧 Customize infrastructure in `terraform/`
- 🐳 Modify application in `app/`
- 🚀 Set up monitoring and logging
- 🔒 Enable HTTPS with SSL certificates

### Need Help?

- Check `PROJECT_SUMMARY.md` for project overview
- Review error messages in CloudWatch Logs
- Check Kubernetes events: `kubectl get events`
- View pod logs: `kubectl logs <pod-name>`

---

**Estimated Total Time**: 30-45 minutes (including AWS resource provisioning)

**Cost Estimate**: ~$50-100/month for dev environment (varies by usage)

🎉 **You're all set! Happy DevOps-ing!**
