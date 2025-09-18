# variables.tf - Niveau 3 + Monitoring

# ================================
# CONFIGURATION INFRASTRUCTURE
# ================================

variable "instance_type" {
  description = "Type d'instance pour les serveurs web"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Nom de la clé SSH"
  type        = string
  default     = "mon-projet-terraform-key"
}

# ================================
# CONFIGURATION BASE DE DONNÉES
# ================================

variable "db_password" {
  description = "Mot de passe pour la base de données MySQL"
  type        = string
  sensitive   = true
  default     = "MonMotDePasseSecurise123!"
}

# ================================
# CONFIGURATION AUTO SCALING
# ================================

variable "min_servers" {
  description = "Nombre minimum de serveurs"
  type        = number
  default     = 2
}

variable "max_servers" {
  description = "Nombre maximum de serveurs"
  type        = number
  default     = 5
}

variable "desired_servers" {
  description = "Nombre désiré de serveurs"
  type        = number
  default     = 2
}

# ================================
# CONFIGURATION MONITORING
# ================================

variable "alert_email" {
  description = "Email pour recevoir les alertes de monitoring"
  type        = string
  default     = "admin@example.com"
}

variable "cpu_high_threshold" {
  description = "Seuil CPU pour déclencher scale up (%)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.cpu_high_threshold > 0 && var.cpu_high_threshold <= 100
    error_message = "Le seuil CPU doit être entre 1 et 100."
  }
}

variable "cpu_low_threshold" {
  description = "Seuil CPU pour déclencher scale down (%)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.cpu_low_threshold > 0 && var.cpu_low_threshold <= 100
    error_message = "Le seuil CPU doit être entre 1 et 100."
  }
}

variable "scale_up_cooldown" {
  description = "Temps d'attente après scale up (secondes)"
  type        = number
  default     = 300
}

variable "scale_down_cooldown" {
  description = "Temps d'attente après scale down (secondes)"
  type        = number
  default     = 300
}

# ================================
# VARIABLES RÉSEAU (optionnelles)
# ================================

variable "vpc_cidr" {
  description = "Plage d'adresses IP du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR du premier subnet public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR du deuxième subnet public"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR du premier subnet privé"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR du deuxième subnet privé"
  type        = string
  default     = "10.0.11.0/24"
}