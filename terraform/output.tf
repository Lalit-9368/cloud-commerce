output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = module.eks.cluster_status
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "rovestore_route53_nameservers" {
  description = "Route 53 nameservers for roveshop.in"
  value       = aws_route53_zone.rovestore.name_servers
}

output "rovestore_acm_certificate_arn" {
  description = "ACM certificate ARN for roveshop.in"
  value       = aws_acm_certificate.rovestore.arn
}
