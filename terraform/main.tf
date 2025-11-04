terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-cloudops-platform"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = data.aws_availability_zones.available.names
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway  = true
  enable_vpn_gateway  = false

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.eks_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      desired_size = var.node_group_desired_size
      max_size     = var.node_group_max_size
      min_size     = var.node_group_min_size
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels = {
        role = "general"
      }
    }
    spot = {
      desired_size = 1
      max_size     = 3
      min_size     = 0
      instance_types = ["t3.medium", "t3a.medium"]
      capacity_type  = "SPOT"
      disk_size      = 50
      labels = {
        role = "spot"
      }
    }
  }

  tags = {
    Environment = var.environment
  }
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  identifier          = "${var.environment}-postgres"
  engine              = "postgres"
  engine_version      = "15.3"
  instance_class      = var.db_instance_class
  allocated_storage   = var.db_allocated_storage
  storage_encrypted   = true

  db_name  = var.db_name
  username = var.db_username
  port     = 5432

  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  allowed_security_groups = [module.eks.cluster_security_group_id]

  backup_retention_period = var.environment == "prod" ? 7 : 3
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  tags = {
    Environment = var.environment
  }
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  bucket_name = "${var.project_name}-${var.environment}-assets"
  environment = var.environment

  enable_versioning = var.environment == "prod" ? true : false
  enable_encryption = true

  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      prefix  = "logs/"

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }
    }
  ]

  tags = {
    Environment = var.environment
  }
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/eks/${var.cluster_name}/app"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Environment = var.environment
  }
}
