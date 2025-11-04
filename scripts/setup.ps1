# setup.ps1 - Windows PowerShell Setup Script
# This script sets up the development environment on Windows

Write-Host "=========================================" -ForegroundColor Blue
Write-Host "CloudOps Platform Setup Script (Windows)" -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "! $Message" -ForegroundColor Yellow
}

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning-Custom "This script should be run as Administrator for best results"
}

# Check AWS CLI
Write-Host "`nChecking for AWS CLI..." -ForegroundColor Cyan
if (Get-Command aws -ErrorAction SilentlyContinue) {
    $awsVersion = aws --version
    Write-Success "AWS CLI is installed ($awsVersion)"
} else {
    Write-Warning-Custom "AWS CLI is not installed"
    Write-Host "Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
}

# Check Terraform
Write-Host "`nChecking for Terraform..." -ForegroundColor Cyan
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    $tfVersion = terraform version
    Write-Success "Terraform is installed ($($tfVersion.Split("`n")[0]))"
} else {
    Write-Warning-Custom "Terraform is not installed"
    Write-Host "Install with: choco install terraform" -ForegroundColor Yellow
}

# Check kubectl
Write-Host "`nChecking for kubectl..." -ForegroundColor Cyan
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    $k8sVersion = kubectl version --client --short 2>$null
    Write-Success "kubectl is installed"
} else {
    Write-Warning-Custom "kubectl is not installed"
    Write-Host "Install with: choco install kubernetes-cli" -ForegroundColor Yellow
}

# Check Docker
Write-Host "`nChecking for Docker..." -ForegroundColor Cyan
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerVersion = docker --version
    Write-Success "Docker is installed ($dockerVersion)"
} else {
    Write-Warning-Custom "Docker is not installed"
    Write-Host "Install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
}

# Check Python and pip
Write-Host "`nChecking for Python..." -ForegroundColor Cyan
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonVersion = python --version
    Write-Success "Python is installed ($pythonVersion)"
    
    # Check Ansible
    if (Get-Command ansible -ErrorAction SilentlyContinue) {
        Write-Success "Ansible is installed"
    } else {
        Write-Warning-Custom "Ansible is not installed. Installing via pip..."
        pip install ansible
    }
} else {
    Write-Warning-Custom "Python is not installed"
}

# Create .env file if it doesn't exist
Write-Host "`nSetting up environment configuration..." -ForegroundColor Cyan
if (-not (Test-Path ".env")) {
    Write-Host "Creating .env file from template..."
    Copy-Item ".env.example" ".env"
    Write-Success ".env file created. Please update with your values."
} else {
    Write-Warning-Custom ".env file already exists"
}

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Cyan
Set-Location terraform
if (Test-Path "terraform.exe" -PathType Any) {
    terraform init
    Write-Success "Terraform initialized"
} else {
    Write-Error-Custom "Terraform not found"
}
Set-Location ..

# Create necessary directories
Write-Host "`nCreating project directories..." -ForegroundColor Cyan
$directories = @(
    "logs",
    "tmp"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Success "Created directory: $dir"
    }
}

Write-Host "`n=========================================" -ForegroundColor Blue
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Blue

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Configure AWS credentials: aws configure"
Write-Host "2. Update .env file with your values"
Write-Host "3. Review and modify terraform\variables.tf"
Write-Host "4. Initialize infrastructure: cd terraform; terraform plan"
Write-Host "5. Deploy infrastructure: terraform apply"

Write-Success "`nHappy DevOps-ing! 🚀"
