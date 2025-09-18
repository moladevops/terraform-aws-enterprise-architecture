# Ajouter à la fin de examples.tfvars
echo '
# ================================
# CONFIGURATION MONITORING LEVEL 3
# ================================

# Email pour recevoir les alertes (OBLIGATOIRE)
alert_email = "ton.email@example.com"

# Configuration auto-scaling
min_servers = 2
max_servers = 5
desired_servers = 2

# Seuils de monitoring
cpu_high_threshold = 80
cpu_low_threshold = 20

# Cooldown periods (secondes)
scale_up_cooldown = 300
scale_down_cooldown = 300

# Mot de passe base de données (SÉCURISÉ)
db_password = "MonMotDePasseSecurise123!"' >> examples.tfvars