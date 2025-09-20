# environments/staging/staging.tfvars
instance_type   = "t3.small"
min_servers     = 2
max_servers     = 4
desired_servers = 2

db_password   = "StagingSecurePass456!"
alert_email   = "TON-EMAIL@gmail.com"
key_pair_name = "mon-projet-terraform-key"

cpu_high_threshold  = 80
cpu_low_threshold   = 20
scale_up_cooldown   = 300
scale_down_cooldown = 300