# Development Environment Terraform Configuration

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "terraform-state-cloudops-platform"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# Use the root module
module "infrastructure" {
  source = "../../"

  environment         = var.environment
  aws_region          = var.aws_region
  project_name        = "cloudops-platform"
  
  # VPC
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  # EKS
  cluster_name            = var.cluster_name
  eks_version             = var.eks_version
  node_group_desired_size = var.node_group_desired_size
  node_group_min_size     = var.node_group_min_size
  node_group_max_size     = var.node_group_max_size
  
  # RDS
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  
  common_tags = var.common_tags
}
