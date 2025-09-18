# outputs.tf - Niveau 3 + Monitoring

# ================================
# ACCÈS PUBLIC - URLS PRINCIPALES
# ================================

output "load_balancer_dns" {
  description = "🚀 URL de ton application (Load Balancer)"
  value       = "http://${aws_lb.main_alb.dns_name}"
}

output "load_balancer_zone_id" {
  description = "Zone ID du Load Balancer"
  value       = aws_lb.main_alb.zone_id
}

# ================================
# INFRASTRUCTURE RÉSEAU
# ================================

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

# ================================
# AUTO SCALING ET LOAD BALANCING
# ================================

output "autoscaling_group_arn" {
  description = "ARN de l'Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.arn
}

output "autoscaling_group_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.name
}

output "launch_template_id" {
  description = "ID du Launch Template"
  value       = aws_launch_template.web_template.id
}

output "target_group_arn" {
  description = "ARN du Target Group"
  value       = aws_lb_target_group.web_tg.arn
}

# ================================
# BASE DE DONNÉES
# ================================

output "database_endpoint" {
  description = "🗄️ Endpoint de la base de données MySQL"
  value       = aws_db_instance.main_database.endpoint
  sensitive   = true
}

output "database_port" {
  description = "Port de la base de données"
  value       = aws_db_instance.main_database.port
}

output "database_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.main_database.db_name
}

# ================================
# STOCKAGE S3
# ================================

output "s3_bucket_name" {
  description = "💾 Nom du bucket S3"
  value       = aws_s3_bucket.app_storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.app_storage.arn
}

output "s3_bucket_url" {
  description = "URL du bucket S3"
  value       = "https://${aws_s3_bucket.app_storage.bucket}.s3.amazonaws.com"
}

# ================================
# MONITORING ET ALERTES
# ================================

output "cloudwatch_dashboard_url" {
  description = "📊 URL du dashboard CloudWatch"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.main_dashboard.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes"
  value       = aws_sns_topic.alerts.arn
}

output "monitoring_alarms" {
  description = "📈 Liste des alarmes configurées"
  value = {
    high_cpu_alarm    = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    low_cpu_alarm     = aws_cloudwatch_metric_alarm.low_cpu.alarm_name
    alb_errors_alarm  = aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name
    rds_cpu_alarm     = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
  }
}

output "autoscaling_policies" {
  description = "🔄 Politiques d'auto-scaling configurées"
  value = {
    scale_up_policy   = aws_autoscaling_policy.scale_up.arn
    scale_down_policy = aws_autoscaling_policy.scale_down.arn
  }
}

# ================================
# SECURITY GROUPS
# ================================

output "security_groups" {
  description = "🛡️ IDs des Security Groups"
  value = {
    alb_sg = aws_security_group.alb_sg.id
    web_sg = aws_security_group.web_sg.id
    db_sg  = aws_security_group.db_sg.id
  }
}

# ================================
# RÉSUMÉ COMPLET DE L'ARCHITECTURE
# ================================

output "architecture_summary" {
  description = "🎯 Résumé complet de ton architecture Level 3 + Monitoring"
  value = <<-EOT
  
  🚀 ARCHITECTURE NIVEAU 3 + MONITORING DÉPLOYÉE AVEC SUCCÈS!
  
  🌐 ACCÈS APPLICATION:
  • URL: http://${aws_lb.main_alb.dns_name}
  • Load Balancer: ${aws_lb.main_alb.dns_name}
  
  📊 INFRASTRUCTURE SCALABLE:
  • Auto Scaling: ${var.min_servers}-${var.max_servers} serveurs
  • Zones: us-east-1a + us-east-1b (Multi-AZ)
  • VPC: ${aws_vpc.vpc_enterprise.id}
  • Instance Type: ${var.instance_type}
  
  🗄️ BASE DE DONNÉES:
  • MySQL 8.0 (${aws_db_instance.main_database.instance_class})
  • Multi-AZ: Haute disponibilité
  • Backups: 7 jours de rétention
  • Endpoint: ${aws_db_instance.main_database.endpoint}
  
  💾 STOCKAGE:
  • S3 Bucket: ${aws_s3_bucket.app_storage.bucket}
  • Versioning: Activé
  • Encryption: Activé
  
  📈 MONITORING CONFIGURÉ:
  • Dashboard: infrastructure-monitoring
  • Alertes Email: ${var.alert_email}
  • CPU Scale Up: >${var.cpu_high_threshold}%
  • CPU Scale Down: <${var.cpu_low_threshold}%
  • Cooldown: ${var.scale_up_cooldown}s
  
  🚨 ALARMES ACTIVES:
  • High CPU (Auto Scaling)
  • Low CPU (Auto Scaling)  
  • ALB 5XX Errors
  • RDS CPU High
  
  🎯 CAPACITÉ: Prêt pour des millions d'utilisateurs!
  🛡️ SÉCURITÉ: Security Groups en cascade
  ⚡ PERFORMANCE: Auto-scaling automatique
  📧 ALERTES: Notifications email en temps réel
  
  EOT
}

# ================================
# INFORMATIONS TECHNIQUES DÉTAILLÉES
# ================================

output "technical_details" {
  description = "🔧 Détails techniques pour le debugging"
  value = {
    # Réseau
    vpc_cidr                = aws_vpc.vpc_enterprise.cidr_block
    availability_zones      = ["us-east-1a", "us-east-1b"]
    public_subnets         = [aws_subnet.public_subnet_1.cidr_block, aws_subnet.public_subnet_2.cidr_block]
    private_subnets        = [aws_subnet.private_subnet_1.cidr_block, aws_subnet.private_subnet_2.cidr_block]
    
    # Compute
    instance_type          = var.instance_type
    ami_id                 = data.aws_ami.ubuntu.id
    launch_template_version = aws_launch_template.web_template.latest_version
    
    # Database
    database_engine        = aws_db_instance.main_database.engine
    database_version       = aws_db_instance.main_database.engine_version
    database_class         = aws_db_instance.main_database.instance_class
    
    # Monitoring
    dashboard_name         = aws_cloudwatch_dashboard.main_dashboard.dashboard_name
    sns_topic_name         = aws_sns_topic.alerts.name
    
    # Scaling
    min_capacity          = aws_autoscaling_group.web_asg.min_size
    max_capacity          = aws_autoscaling_group.web_asg.max_size
    desired_capacity      = aws_autoscaling_group.web_asg.desired_capacity
  }
}

# ================================
# COMMANDES UTILES
# ================================

output "useful_commands" {
  description = "💡 Commandes utiles pour la gestion"
  value = <<-EOT
  
  📋 COMMANDES UTILES:
  
  🔍 MONITORING:
  • Dashboard: aws cloudwatch get-dashboard --dashboard-name infrastructure-monitoring
  • Métriques: aws cloudwatch list-metrics --namespace AWS/EC2
  
  🔄 AUTO SCALING:
  • Status: aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${aws_autoscaling_group.web_asg.name}
  • Instances: aws autoscaling describe-auto-scaling-instances
  
  🗄️ DATABASE:
  • Connect: mysql -h ${aws_db_instance.main_database.endpoint} -u admin -p
  • Status: aws rds describe-db-instances --db-instance-identifier ${aws_db_instance.main_database.id}
  
  💾 S3:
  • List: aws s3 ls s3://${aws_s3_bucket.app_storage.bucket}
  • Upload: aws s3 cp file.txt s3://${aws_s3_bucket.app_storage.bucket}/
  
  ⚖️ LOAD BALANCER:
  • Health: aws elbv2 describe-target-health --target-group-arn ${aws_lb_target_group.web_tg.arn}
  • Metrics: aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB
  
  EOT
}