# environments/dev/dev.tfvars
instance_type   = "t3.micro"
min_servers     = 1
max_servers     = 2
desired_servers = 1

db_password   = "DevPassword123!"
alert_email   = "TON-EMAIL@gmail.com"
key_pair_name = "mon-projet-terraform-key"

cpu_high_threshold  = 85
cpu_low_threshold   = 15
scale_up_cooldown   = 180
scale_down_cooldown = 180