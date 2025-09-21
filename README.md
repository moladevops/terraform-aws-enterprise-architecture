# 🚀 Architecture AWS Enterprise avec Terraform

![Terraform](https://img.shields.io/badge/Terraform-v1.5+-purple?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)
![License](https://img.shields.io/badge/License-MIT-blue)

## 📋 Description

Infrastructure AWS scalable et hautement disponible déployée avec Terraform. Cette architecture peut supporter des millions d'utilisateurs avec auto-scaling, load balancing, et haute disponibilité multi-AZ.

## 🏗️ Architecture

```
🌐 Internet
    ↓
⚖️ Application Load Balancer
    ↓
🔄 Auto Scaling Group (2-5 instances)
    ↓
💻 EC2 Instances (Multi-AZ)
    ↓
🗄️ RDS MySQL (Multi-AZ)
    ↓
💾 S3 Storage (Versioning)
```

## ✨ Fonctionnalités

- **🔄 Auto Scaling** : Serveurs qui s'adaptent automatiquement à la charge
- **⚖️ Load Balancing** : Répartition intelligente du trafic
- **🛡️ Sécurité** : Security Groups en cascade + subnets privés
- **🗄️ Base de données** : MySQL managé avec backups automatiques
- **🌍 Multi-AZ** : Déploiement dans plusieurs zones de disponibilité
- **💾 Stockage** : S3 avec versioning et protection des données
- **📊 Monitoring** : Health checks automatiques

## 🛠️ Technologies utilisées

- **Terraform** v1.5+
- **AWS Provider** v5.0+
- **Ubuntu** 22.04 LTS
- **Nginx** Web Server
- **MySQL** 8.0 (RDS)
- **S3** Storage

## 📋 Prérequis

### Outils requis
```bash
# Terraform
terraform --version  # >= 1.5.0

# AWS CLI
aws --version        # >= 2.0.0

# Git
git --version
```

### Configuration AWS
```bash
# Configurer AWS CLI
aws configure

# Vérifier l'accès
aws sts get-caller-identity
```

### Clé SSH
- Créer une clé SSH dans AWS EC2 → Key Pairs
- Noter le nom exact de la clé

## 🚀 Déploiement rapide

### 1. Cloner le repository
```bash
git clone https://github.com/VOTRE-USERNAME/terraform-aws-enterprise.git
cd terraform-aws-enterprise
```

### 2. Configurer les variables
```bash
# Copier le template
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
nano terraform.tfvars
```

### 3. Déployer l'infrastructure
```bash
# Initialiser Terraform
terraform init

# Planifier les changements
terraform plan

# Appliquer l'infrastructure
terraform apply
```

### 4. Accéder à l'application
```bash
# Récupérer l'URL de l'application
terraform output load_balancer_dns
```

## ⚙️ Configuration

### Variables principales

| Variable | Description | Défaut | Requis |
|----------|-------------|--------|--------|
| `instance_type` | Type d'instance EC2 | `t3.micro` | Non |
| `key_pair_name` | Nom de la clé SSH AWS | - | **Oui** |
| `db_password` | Mot de passe base de données | - | **Oui** |
| `min_servers` | Nombre minimum de serveurs | `2` | Non |
| `max_servers` | Nombre maximum de serveurs | `5` | Non |

### Exemple terraform.tfvars
```hcl
# terraform.tfvars
instance_type   = "t3.micro"
key_pair_name   = "ma-cle-ssh"
db_password     = "MonMotDePasseSecurise123!"
min_servers     = 2
max_servers     = 5
desired_servers = 2
```

## 📊 Ressources créées

| Type | Nombre | Description |
|------|--------|-------------|
| VPC | 1 | Réseau privé virtuel |
| Subnets | 4 | 2 publics + 2 privés (Multi-AZ) |
| Load Balancer | 1 | Application Load Balancer |
| Auto Scaling Group | 1 | Groupe d'auto-scaling |
| EC2 Instances | 2-5 | Serveurs web Ubuntu |
| RDS Instance | 1 | Base de données MySQL |
| S3 Bucket | 1 | Stockage avec versioning |
| Security Groups | 3 | ALB, Web, Database |

## 🔒 Sécurité

### Architecture sécurisée
- **Subnets privés** : Base de données isolée d'Internet
- **Security Groups** : Pare-feu en cascade (ALB → Web → DB)
- **Chiffrement** : Base de données et S3 chiffrés
- **Accès contrôlé** : SSH uniquement sur instances web

### Bonnes pratiques appliquées
- ✅ Principle of least privilege
- ✅ Defense in depth
- ✅ Encryption at rest
- ✅ Network segmentation
- ✅ Automated backups

## 📈 Monitoring et maintenance

### Outputs disponibles
```bash
# URL de l'application
terraform output load_balancer_dns

# Informations base de données
terraform output database_endpoint

# Bucket S3
terraform output s3_bucket_name

# Résumé complet
terraform output architecture_summary
```

### Health checks
- **Load Balancer** : Vérifie la santé des instances
- **Auto Scaling** : Remplace automatiquement les instances défaillantes
- **RDS** : Backups automatiques quotidiens

## 💰 Coûts estimés

| Service | Type | Coût mensuel (us-east-1) |
|---------|------|--------------------------|
| EC2 t3.micro | 2 instances | ~$16.80 |
| ALB | Application LB | ~$22.50 |
| RDS t3.micro | MySQL | ~$15.84 |
| S3 | Standard | ~$0.50 |
| **Total** | | **~$55.64/mois** |

> 💡 **Note** : Coûts indicatifs. Utilisez AWS Cost Calculator pour une estimation précise.

## 🧪 Tests

### Test de charge
```bash
# Installer Apache Bench
sudo apt-get install apache2-utils

# Test de charge basique
ab -n 1000 -c 10 http://VOTRE-ALB-URL/
```

### Test d'auto-scaling
```bash
# Générer de la charge pour déclencher l'auto-scaling
ab -n 10000 -c 100 http://VOTRE-ALB-URL/
```

## 🔧 Dépannage

### Problèmes courants

**1. Erreur de clé SSH**
```bash
Error: invalid key pair name
```
Solution : Vérifier que la clé existe dans la région us-east-1

**2. Timeout de déploiement**
```bash
Error: timeout while waiting for resource
```
Solution : Vérifier les limites de votre compte AWS

**3. Erreur de mot de passe DB**
```bash
Error: password does not meet requirements
```
Solution : Le mot de passe doit contenir majuscules, minuscules, chiffres et caractères spéciaux

### Logs utiles
```bash
# Logs Terraform
export TF_LOG=DEBUG
terraform apply

# Logs d'instance EC2
aws logs describe-log-groups --region us-east-1
```

## 🗑️ Nettoyage

```bash
# Supprimer toute l'infrastructure
terraform destroy

# Confirmer avec 'yes'
```

> ⚠️ **Attention** : Cette commande supprime TOUTES les ressources, y compris la base de données !

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📞 Support

- 📧 Email : votre-email@example.com
- 💬 Issues : [GitHub Issues](https://github.com/VOTRE-USERNAME/terraform-aws-enterprise/issues)
- 📖 Documentation : [Wiki](https://github.com/VOTRE-USERNAME/terraform-aws-enterprise/wiki)

## 📄 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🏆 Auteur

**Votre Nom** - DevOps Engineer

- GitHub: [@votre-username](https://github.com/votre-username)
- LinkedIn: [Votre Profil](https://linkedin.com/in/votre-profil)

## 🙏 Remerciements

- [HashiCorp Terraform](https://terraform.io) pour l'outil fantastique
- [AWS](https://aws.amazon.com) pour l'infrastructure cloud
- Communauté DevOps pour les bonnes pratiques

---

**⭐ Si ce projet vous aide, n'hésitez pas à lui donner une étoile !**# VPC limit issue resolved
