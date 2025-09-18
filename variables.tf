# variables.tf - Niveau 3

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

variable "db_password" {
  description = "Mot de passe pour la base de données MySQL"
  type        = string
  sensitive   = true
  default     = "MonMotDePasseSecurise123!"
}

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