# outputs.tf - Niveau 3

# 🌐 ACCÈS PUBLIC
output "load_balancer_dns" {
  description = "🚀 URL de ton application (Load Balancer)"
  value       = "http://${aws_lb.main_alb.dns_name}"
}

output "load_balancer_zone_id" {
  description = "Zone ID du Load Balancer"
  value       = aws_lb.main_alb.zone_id
}

# 🏗️ INFRASTRUCTURE
output "vpc_id" {
  description = "ID du VPC Enterprise"
  value       = aws_vpc.vpc_enterprise.id
}

output "public_subnet_ids" {
  description = "IDs des subnets publics"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnet_ids" {
  description = "IDs des subnets privés"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

# 🔄 AUTO SCALING
output "autoscaling_group_arn" {
  description = "ARN de l'Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.arn
}

output "launch_template_id" {
  description = "ID du Launch Template"
  value       = aws_launch_template.web_template.id
}

# 🗄️ BASE DE DONNÉES
output "database_endpoint" {
  description = "🗄️ Endpoint de la base de données MySQL"
  value       = aws_db_instance.main_database.endpoint
  sensitive   = true
}

output "database_port" {
  description = "Port de la base de données"
  value       = aws_db_instance.main_database.port
}

# 💾 STOCKAGE
output "s3_bucket_name" {
  description = "💾 Nom du bucket S3"
  value       = aws_s3_bucket.app_storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.app_storage.arn
}

# 📊 MONITORING
output "target_group_arn" {
  description = "ARN du Target Group"
  value       = aws_lb_target_group.web_tg.arn
}

# 🎯 RÉSUMÉ ARCHITECTURE
output "architecture_summary" {
  description = "🎯 Résumé de ton architecture Level 3"
  value = <<-EOT
  
  🚀 ARCHITECTURE NIVEAU 3 DÉPLOYÉE AVEC SUCCÈS!
  
  🌐 URL APPLICATION: http://${aws_lb.main_alb.dns_name}
  
  📊 INFRASTRUCTURE:
  • Load Balancer: ${aws_lb.main_alb.dns_name}
  • Auto Scaling: ${var.min_servers}-${var.max_servers} serveurs
  • Base de données: MySQL 8.0 Multi-AZ
  • Stockage: S3 avec versioning
  • Zones: us-east-1a + us-east-1b
  
  🎯 CAPACITÉ: Prêt pour des millions d'utilisateurs!
  
  EOT
}

# 🔧 INFORMATIONS TECHNIQUES
output "technical_details" {
  description = "Détails techniques pour le debugging"
  value = {
    vpc_cidr           = aws_vpc.vpc_enterprise.cidr_block
    availability_zones = ["us-east-1a", "us-east-1b"]
    instance_type      = var.instance_type
    database_engine    = aws_db_instance.main_database.engine
    database_version   = aws_db_instance.main_database.engine_version
  }
}