# main.tf - NIVEAU 3 : Architecture Enterprise Scalable + Monitoring

# RANDOM ID - D√âPLAC√â AU D√âBUT POUR √äTRE DISPONIBLE PARTOUT
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# 1. R√âSEAU PRIV√â MULTI-ZONES
resource "aws_vpc" "vpc_enterprise" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-Enterprise-Level3-${random_id.bucket_suffix.hex}"
  }
}

# 2. INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_enterprise.id

  tags = {
    Name = "IGW-Enterprise-${random_id.bucket_suffix.hex}"
  }
}

# 3. SUBNETS PUBLICS DANS 2 ZONES (Haute Disponibilit√©)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc_enterprise.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1a-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc_enterprise.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1b-${random_id.bucket_suffix.hex}"
  }
}

# 4. SUBNETS PRIV√âS POUR LA BASE DE DONN√âES
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc_enterprise.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-Subnet-1a-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc_enterprise.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private-Subnet-1b-${random_id.bucket_suffix.hex}"
  }
}

# 5. TABLE DE ROUTAGE PUBLIQUE
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_enterprise.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table-${random_id.bucket_suffix.hex}"
  }
}

# 6. ASSOCIATIONS SUBNETS PUBLICS
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. SECURITY GROUP POUR LOAD BALANCER
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group-${random_id.bucket_suffix.hex}"
  description = "Security group pour Application Load Balancer"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS public"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout trafic sortant"
  }

  tags = {
    Name = "ALB-Security-Group-${random_id.bucket_suffix.hex}"
  }
}

# 8. SECURITY GROUP POUR INSTANCES EC2
resource "aws_security_group" "web_sg" {
  name        = "web-instances-sg-${random_id.bucket_suffix.hex}"
  description = "Security group pour instances web"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "HTTP depuis Load Balancer"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH pour maintenance"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout trafic sortant"
  }

  tags = {
    Name = "Web-Instances-SG-${random_id.bucket_suffix.hex}"
  }
}

# 9. SECURITY GROUP POUR BASE DE DONN√âES
resource "aws_security_group" "db_sg" {
  name        = "database-sg-${random_id.bucket_suffix.hex}"
  description = "Security group pour base de donnees"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
    description     = "MySQL depuis instances web"
  }

  tags = {
    Name = "Database-SG-${random_id.bucket_suffix.hex}"
  }
}

# 10. TROUVER L'AMI UBUNTU
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 11. LAUNCH TEMPLATE POUR AUTO SCALING
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-template-${random_id.bucket_suffix.hex}-"
  description   = "Template pour instances web"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx awscli
              
              cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Ì∫Ä Architecture Niveau 3 - Scalable + Monitoring!</title>
    <style>
        body { font-family: Arial; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 10px; }
        h1 { color: #FFD700; }
        .info { background: rgba(255,255,255,0.2); padding: 15px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Ì∫Ä NIVEAU 3 - Architecture Enterprise + Monitoring!</h1>
        <div class="info">
            <h2>ÌøóÔ∏è Infrastructure Scalable</h2>
            <p>‚úÖ Load Balancer</p>
            <p>‚úÖ Auto Scaling Group</p>
            <p>‚úÖ Multi-AZ Deployment</p>
            <p>‚úÖ RDS Database</p>
            <p>‚úÖ S3 Storage</p>
            <p>‚úÖ CloudWatch Monitoring</p>
            <p>‚úÖ Email Alerts</p>
        </div>
        <div class="info">
            <h3>Ì≥ä Instance Info:</h3>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
            <p><strong>Time:</strong> <span id="time"></span></p>
        </div>
        <div class="info">
            <h3>ÌæØ Production Ready!</h3>
            <p>Cette architecture peut g√©rer des millions d'utilisateurs!</p>
            <p>Monitoring automatique avec alertes email!</p>
        </div>
    </div>
    
    <script>
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'N/A');
            
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(() => document.getElementById('az').textContent = 'N/A');
            
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
HTML
              
              systemctl start nginx
              systemctl enable nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web-Server-AutoScaling-${random_id.bucket_suffix.hex}"
    }
  }
}

# 12. APPLICATION LOAD BALANCER
resource "aws_lb" "main_alb" {
  name               = "main-alb-${random_id.bucket_suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Main-Application-LoadBalancer-${random_id.bucket_suffix.hex}"
  }
}

# 13. TARGET GROUP POUR LOAD BALANCER
resource "aws_lb_target_group" "web_tg" {
  name     = "web-targets-${random_id.bucket_suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_enterprise.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Web-Target-Group-${random_id.bucket_suffix.hex}"
  }
}

# 14. LISTENER POUR LOAD BALANCER
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 15. AUTO SCALING GROUP
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-autoscaling-group-${random_id.bucket_suffix.hex}"
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  min_size         = var.min_servers
  max_size         = var.max_servers
  desired_capacity = var.desired_servers

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Web-Server-ASG-${random_id.bucket_suffix.hex}"
    propagate_at_launch = true
  }
}

# 16. SUBNET GROUP POUR RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group-${random_id.bucket_suffix.hex}"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "DB-Subnet-Group-${random_id.bucket_suffix.hex}"
  }
}

# 17. BASE DE DONN√âES RDS
resource "aws_db_instance" "main_database" {
  identifier = "main-database-${random_id.bucket_suffix.hex}"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "webapp"
  username = "admin"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "Main-Database-${random_id.bucket_suffix.hex}"
  }
}

# 18. BUCKET S3 AVEC VERSIONING
resource "aws_s3_bucket" "app_storage" {
  bucket = "app-storage-level3-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "App-Storage-Level3-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ================================
# MONITORING ET ALERTES CLOUDWATCH
# ================================

# 19. SNS TOPIC POUR NOTIFICATIONS
resource "aws_sns_topic" "alerts" {
  name = "infrastructure-alerts-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "Infrastructure-Alerts-${random_id.bucket_suffix.hex}"
  }
}

# 20. SUBSCRIPTION EMAIL POUR ALERTES
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  depends_on = [aws_sns_topic.alerts]
}

# 21. POLICY AUTO SCALING - SCALE UP
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy-${random_id.bucket_suffix.hex}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  policy_type = "SimpleScaling"
}

# 22. POLICY AUTO SCALING - SCALE DOWN
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy-${random_id.bucket_suffix.hex}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  policy_type = "SimpleScaling"
}

# 23. CLOUDWATCH ALARME - CPU √âLEV√â (Scale Up)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  tags = {
    Name = "High-CPU-Alarm-${random_id.bucket_suffix.hex}"
  }
}

# 24. CLOUDWATCH ALARME - CPU FAIBLE (Scale Down)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-utilization-${random_id.bucket_suffix.hex}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  tags = {
    Name = "Low-CPU-Alarm-${random_id.bucket_suffix.hex}"
  }
}

# 25. ALARME LOAD BALANCER - R√âPONSES 5XX
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "alb-high-5xx-errors-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main_alb.arn_suffix
  }

  tags = {
    Name = "ALB-5XX-Errors-${random_id.bucket_suffix.hex}"
  }
}

# 26. ALARME BASE DE DONN√âES - CPU
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "rds-high-cpu-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main_database.id
  }

  tags = {
    Name = "RDS-High-CPU-${random_id.bucket_suffix.hex}"
  }
}

# 27. DASHBOARD CLOUDWATCH
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "infrastructure-monitoring-${random_id.bucket_suffix.hex}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web_asg.name],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main_database.id]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Infrastructure Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.main_alb.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Application Health"
        }
      }
    ]
  })
}
EOFcat > main.tf << 'EOF'
# main.tf - NIVEAU 3 : Architecture Enterprise Scalable + Monitoring

# RANDOM ID - D√âPLAC√â AU D√âBUT POUR √äTRE DISPONIBLE PARTOUT
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# 1. R√âSEAU PRIV√â MULTI-ZONES
resource "aws_vpc" "vpc_enterprise" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-Enterprise-Level3-${random_id.bucket_suffix.hex}"
  }
}

# 2. INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_enterprise.id

  tags = {
    Name = "IGW-Enterprise-${random_id.bucket_suffix.hex}"
  }
}

# 3. SUBNETS PUBLICS DANS 2 ZONES (Haute Disponibilit√©)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc_enterprise.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1a-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc_enterprise.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1b-${random_id.bucket_suffix.hex}"
  }
}

# 4. SUBNETS PRIV√âS POUR LA BASE DE DONN√âES
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc_enterprise.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-Subnet-1a-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc_enterprise.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private-Subnet-1b-${random_id.bucket_suffix.hex}"
  }
}

# 5. TABLE DE ROUTAGE PUBLIQUE
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_enterprise.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table-${random_id.bucket_suffix.hex}"
  }
}

# 6. ASSOCIATIONS SUBNETS PUBLICS
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. SECURITY GROUP POUR LOAD BALANCER
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group-${random_id.bucket_suffix.hex}"
  description = "Security group pour Application Load Balancer"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS public"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout trafic sortant"
  }

  tags = {
    Name = "ALB-Security-Group-${random_id.bucket_suffix.hex}"
  }
}

# 8. SECURITY GROUP POUR INSTANCES EC2
resource "aws_security_group" "web_sg" {
  name        = "web-instances-sg-${random_id.bucket_suffix.hex}"
  description = "Security group pour instances web"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "HTTP depuis Load Balancer"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH pour maintenance"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout trafic sortant"
  }

  tags = {
    Name = "Web-Instances-SG-${random_id.bucket_suffix.hex}"
  }
}

# 9. SECURITY GROUP POUR BASE DE DONN√âES
resource "aws_security_group" "db_sg" {
  name        = "database-sg-${random_id.bucket_suffix.hex}"
  description = "Security group pour base de donnees"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
    description     = "MySQL depuis instances web"
  }

  tags = {
    Name = "Database-SG-${random_id.bucket_suffix.hex}"
  }
}

# 10. TROUVER L'AMI UBUNTU
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 11. LAUNCH TEMPLATE POUR AUTO SCALING
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-template-${random_id.bucket_suffix.hex}-"
  description   = "Template pour instances web"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx awscli
              
              cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Ì∫Ä Architecture Niveau 3 - Scalable + Monitoring!</title>
    <style>
        body { font-family: Arial; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 10px; }
        h1 { color: #FFD700; }
        .info { background: rgba(255,255,255,0.2); padding: 15px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Ì∫Ä NIVEAU 3 - Architecture Enterprise + Monitoring!</h1>
        <div class="info">
            <h2>ÌøóÔ∏è Infrastructure Scalable</h2>
            <p>‚úÖ Load Balancer</p>
            <p>‚úÖ Auto Scaling Group</p>
            <p>‚úÖ Multi-AZ Deployment</p>
            <p>‚úÖ RDS Database</p>
            <p>‚úÖ S3 Storage</p>
            <p>‚úÖ CloudWatch Monitoring</p>
            <p>‚úÖ Email Alerts</p>
        </div>
        <div class="info">
            <h3>Ì≥ä Instance Info:</h3>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
            <p><strong>Time:</strong> <span id="time"></span></p>
        </div>
        <div class="info">
            <h3>ÌæØ Production Ready!</h3>
            <p>Cette architecture peut g√©rer des millions d'utilisateurs!</p>
            <p>Monitoring automatique avec alertes email!</p>
        </div>
    </div>
    
    <script>
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'N/A');
            
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(() => document.getElementById('az').textContent = 'N/A');
            
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
HTML
              
              systemctl start nginx
              systemctl enable nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web-Server-AutoScaling-${random_id.bucket_suffix.hex}"
    }
  }
}

# 12. APPLICATION LOAD BALANCER
resource "aws_lb" "main_alb" {
  name               = "main-alb-${random_id.bucket_suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Main-Application-LoadBalancer-${random_id.bucket_suffix.hex}"
  }
}

# 13. TARGET GROUP POUR LOAD BALANCER
resource "aws_lb_target_group" "web_tg" {
  name     = "web-targets-${random_id.bucket_suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_enterprise.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Web-Target-Group-${random_id.bucket_suffix.hex}"
  }
}

# 14. LISTENER POUR LOAD BALANCER
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 15. AUTO SCALING GROUP
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-autoscaling-group-${random_id.bucket_suffix.hex}"
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  min_size         = var.min_servers
  max_size         = var.max_servers
  desired_capacity = var.desired_servers

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Web-Server-ASG-${random_id.bucket_suffix.hex}"
    propagate_at_launch = true
  }
}

# 16. SUBNET GROUP POUR RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group-${random_id.bucket_suffix.hex}"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "DB-Subnet-Group-${random_id.bucket_suffix.hex}"
  }
}

# 17. BASE DE DONN√âES RDS
resource "aws_db_instance" "main_database" {
  identifier = "main-database-${random_id.bucket_suffix.hex}"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "webapp"
  username = "admin"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "Main-Database-${random_id.bucket_suffix.hex}"
  }
}

# 18. BUCKET S3 AVEC VERSIONING
resource "aws_s3_bucket" "app_storage" {
  bucket = "app-storage-level3-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "App-Storage-Level3-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ================================
# MONITORING ET ALERTES CLOUDWATCH
# ================================

# 19. SNS TOPIC POUR NOTIFICATIONS
resource "aws_sns_topic" "alerts" {
  name = "infrastructure-alerts-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "Infrastructure-Alerts-${random_id.bucket_suffix.hex}"
  }
}

# 20. SUBSCRIPTION EMAIL POUR ALERTES
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  depends_on = [aws_sns_topic.alerts]
}

# 21. POLICY AUTO SCALING - SCALE UP
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy-${random_id.bucket_suffix.hex}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  policy_type = "SimpleScaling"
}

# 22. POLICY AUTO SCALING - SCALE DOWN
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy-${random_id.bucket_suffix.hex}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  policy_type = "SimpleScaling"
}

# 23. CLOUDWATCH ALARME - CPU √âLEV√â (Scale Up)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  tags = {
    Name = "High-CPU-Alarm-${random_id.bucket_suffix.hex}"
  }
}

# 24. CLOUDWATCH ALARME - CPU FAIBLE (Scale Down)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-utilization-${random_id.bucket_suffix.hex}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  tags = {
    Name = "Low-CPU-Alarm-${random_id.bucket_suffix.hex}"
  }
}

# 25. ALARME LOAD BALANCER - R√âPONSES 5XX
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "alb-high-5xx-errors-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main_alb.arn_suffix
  }

  tags = {
    Name = "ALB-5XX-Errors-${random_id.bucket_suffix.hex}"
  }
}

# 26. ALARME BASE DE DONN√âES - CPU
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "rds-high-cpu-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main_database.id
  }

  tags = {
    Name = "RDS-High-CPU-${random_id.bucket_suffix.hex}"
  }
}

# 27. DASHBOARD CLOUDWATCH
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "infrastructure-monitoring-${random_id.bucket_suffix.hex}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web_asg.name],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main_database.id]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Infrastructure Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.main_alb.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Application Health"
        }
      }
    ]
  })
}
EOFcat > main.tf << 'EOF'
# main.tf - NIVEAU 3 : Architecture Enterprise Scalable + Monitoring

# RANDOM ID - D√âPLAC√â AU D√âBUT POUR √äTRE DISPONIBLE PARTOUT
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# 1. R√âSEAU PRIV√â MULTI-ZONES
resource "aws_vpc" "vpc_enterprise" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-Enterprise-Level3-${random_id.bucket_suffix.hex}"
  }
}

# 2. INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_enterprise.id

  tags = {
    Name = "IGW-Enterprise-${random_id.bucket_suffix.hex}"
  }
}

# 3. SUBNETS PUBLICS DANS 2 ZONES (Haute Disponibilit√©)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc_enterprise.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1a-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc_enterprise.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1b-${random_id.bucket_suffix.hex}"
  }
}

# 4. SUBNETS PRIV√âS POUR LA BASE DE DONN√âES
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc_enterprise.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-Subnet-1a-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc_enterprise.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private-Subnet-1b-${random_id.bucket_suffix.hex}"
  }
}

# 5. TABLE DE ROUTAGE PUBLIQUE
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_enterprise.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table-${random_id.bucket_suffix.hex}"
  }
}

# 6. ASSOCIATIONS SUBNETS PUBLICS
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. SECURITY GROUP POUR LOAD BALANCER
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group-${random_id.bucket_suffix.hex}"
  description = "Security group pour Application Load Balancer"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS public"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout trafic sortant"
  }

  tags = {
    Name = "ALB-Security-Group-${random_id.bucket_suffix.hex}"
  }
}

# 8. SECURITY GROUP POUR INSTANCES EC2
resource "aws_security_group" "web_sg" {
  name        = "web-instances-sg-${random_id.bucket_suffix.hex}"
  description = "Security group pour instances web"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "HTTP depuis Load Balancer"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH pour maintenance"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout trafic sortant"
  }

  tags = {
    Name = "Web-Instances-SG-${random_id.bucket_suffix.hex}"
  }
}

# 9. SECURITY GROUP POUR BASE DE DONN√âES
resource "aws_security_group" "db_sg" {
  name        = "database-sg-${random_id.bucket_suffix.hex}"
  description = "Security group pour base de donnees"
  vpc_id      = aws_vpc.vpc_enterprise.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
    description     = "MySQL depuis instances web"
  }

  tags = {
    Name = "Database-SG-${random_id.bucket_suffix.hex}"
  }
}

# 10. TROUVER L'AMI UBUNTU
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 11. LAUNCH TEMPLATE POUR AUTO SCALING
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-template-${random_id.bucket_suffix.hex}-"
  description   = "Template pour instances web"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx awscli
              
              cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Ì∫Ä Architecture Niveau 3 - Scalable + Monitoring!</title>
    <style>
        body { font-family: Arial; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 10px; }
        h1 { color: #FFD700; }
        .info { background: rgba(255,255,255,0.2); padding: 15px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Ì∫Ä NIVEAU 3 - Architecture Enterprise + Monitoring!</h1>
        <div class="info">
            <h2>ÌøóÔ∏è Infrastructure Scalable</h2>
            <p>‚úÖ Load Balancer</p>
            <p>‚úÖ Auto Scaling Group</p>
            <p>‚úÖ Multi-AZ Deployment</p>
            <p>‚úÖ RDS Database</p>
            <p>‚úÖ S3 Storage</p>
            <p>‚úÖ CloudWatch Monitoring</p>
            <p>‚úÖ Email Alerts</p>
        </div>
        <div class="info">
            <h3>Ì≥ä Instance Info:</h3>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
            <p><strong>Time:</strong> <span id="time"></span></p>
        </div>
        <div class="info">
            <h3>ÌæØ Production Ready!</h3>
            <p>Cette architecture peut g√©rer des millions d'utilisateurs!</p>
            <p>Monitoring automatique avec alertes email!</p>
        </div>
    </div>
    
    <script>
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'N/A');
            
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(() => document.getElementById('az').textContent = 'N/A');
            
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
HTML
              
              systemctl start nginx
              systemctl enable nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web-Server-AutoScaling-${random_id.bucket_suffix.hex}"
    }
  }
}

# 12. APPLICATION LOAD BALANCER
resource "aws_lb" "main_alb" {
  name               = "main-alb-${random_id.bucket_suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Main-Application-LoadBalancer-${random_id.bucket_suffix.hex}"
  }
}

# 13. TARGET GROUP POUR LOAD BALANCER
resource "aws_lb_target_group" "web_tg" {
  name     = "web-targets-${random_id.bucket_suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_enterprise.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Web-Target-Group-${random_id.bucket_suffix.hex}"
  }
}

# 14. LISTENER POUR LOAD BALANCER
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 15. AUTO SCALING GROUP
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-autoscaling-group-${random_id.bucket_suffix.hex}"
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  min_size         = var.min_servers
  max_size         = var.max_servers
  desired_capacity = var.desired_servers

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Web-Server-ASG-${random_id.bucket_suffix.hex}"
    propagate_at_launch = true
  }
}

# 16. SUBNET GROUP POUR RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group-${random_id.bucket_suffix.hex}"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "DB-Subnet-Group-${random_id.bucket_suffix.hex}"
  }
}

# 17. BASE DE DONN√âES RDS
resource "aws_db_instance" "main_database" {
  identifier = "main-database-${random_id.bucket_suffix.hex}"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "webapp"
  username = "admin"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "Main-Database-${random_id.bucket_suffix.hex}"
  }
}

# 18. BUCKET S3 AVEC VERSIONING
resource "aws_s3_bucket" "app_storage" {
  bucket = "app-storage-level3-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "App-Storage-Level3-${random_id.bucket_suffix.hex}"
  }
}

resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ================================
# MONITORING ET ALERTES CLOUDWATCH
# ================================

# 19. SNS TOPIC POUR NOTIFICATIONS
resource "aws_sns_topic" "alerts" {
  name = "infrastructure-alerts-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "Infrastructure-Alerts-${random_id.bucket_suffix.hex}"
  }
}

# 20. SUBSCRIPTION EMAIL POUR ALERTES
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  depends_on = [aws_sns_topic.alerts]
}

# 21. POLICY AUTO SCALING - SCALE UP
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy-${random_id.bucket_suffix.hex}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  policy_type = "SimpleScaling"
}

# 22. POLICY AUTO SCALING - SCALE DOWN
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy-${random_id.bucket_suffix.hex}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  policy_type = "SimpleScaling"
}

# 23. CLOUDWATCH ALARME - CPU √âLEV√â (Scale Up)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  tags = {
    Name = "High-CPU-Alarm-${random_id.bucket_suffix.hex}"
  }
}

# 24. CLOUDWATCH ALARME - CPU FAIBLE (Scale Down)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-utilization-${random_id.bucket_suffix.hex}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  tags = {
    Name = "Low-CPU-Alarm-${random_id.bucket_suffix.hex}"
  }
}

# 25. ALARME LOAD BALANCER - R√âPONSES 5XX
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "alb-high-5xx-errors-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main_alb.arn_suffix
  }

  tags = {
    Name = "ALB-5XX-Errors-${random_id.bucket_suffix.hex}"
  }
}

# 26. ALARME BASE DE DONN√âES - CPU
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "rds-high-cpu-${random_id.bucket_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main_database.id
  }

  tags = {
    Name = "RDS-High-CPU-${random_id.bucket_suffix.hex}"
  }
}

# 27. DASHBOARD CLOUDWATCH
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "infrastructure-monitoring-${random_id.bucket_suffix.hex}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web_asg.name],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main_database.id]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Infrastructure Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", aws_lb.main_alb.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.web_tg.arn_suffix, "LoadBalancer", aws_lb.main_alb.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Application Health"
        }
      }
    ]
  })
}
