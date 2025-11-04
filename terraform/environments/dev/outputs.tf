output "vpc_id" {
  description = "VPC ID"
  value       = module.infrastructure.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.infrastructure.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.infrastructure.eks_cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = module.infrastructure.configure_kubectl
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.infrastructure.rds_endpoint
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.infrastructure.ecr_repository_url
}
