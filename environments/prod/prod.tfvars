# environments/prod/prod.tfvars
instance_type   = "t3.medium"
min_servers     = 3
max_servers     = 10
desired_servers = 3

db_password   = "ProductionUltraSecure789!"
alert_email   = "TON-EMAIL@gmail.com"
key_pair_name = "mon-projet-terraform-key"

cpu_high_threshold  = 75
cpu_low_threshold   = 25
scale_up_cooldown   = 300
scale_down_cooldown = 600