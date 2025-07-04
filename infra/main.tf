terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "voting-app-terraform-state-177816"
    key            = "voting-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}


provider "aws" {
  region  = var.aws_region
}

# ECR Repositories
module "ecr_vote" {
  source = "./modules/ecr-repo"
  name   = "voting-app-vote-${terraform.workspace}"
  tags   = merge(var.tags, { Environment = terraform.workspace })
}

module "ecr_result" {
  source = "./modules/ecr-repo"
  name   = "voting-app-result-${terraform.workspace}"
  tags   = merge(var.tags, { Environment = terraform.workspace })
}

module "ecr_seed" {
  source = "./modules/ecr-repo"
  name   = "voting-app-seed-data-${terraform.workspace}"
  tags   = merge(var.tags, { Environment = terraform.workspace })
}

module "ecr_worker" {
  source = "./modules/ecr-repo"
  name   = "voting-app-worker-${terraform.workspace}"
  tags   = merge(var.tags, { Environment = terraform.workspace })
}


# Modulo de Network
module "network" {
  source = "./modules/network"

  vpc_cidr           = var.vpc_cidr
  public_subnets_cidrs = var.public_subnets_cidrs
  availability_zones = var.availability_zones
  region             = var.aws_region
  tags               = var.tags
}

# Modulo Security Group
module "security_group" {
  source = "./modules/security_group"

  vpc_id = module.network.vpc_id
  sg_name = "nsg-voting-app"

  tags = var.tags
}

# Modulo EKS Cluster
module "eks_cluster" {
  source              = "./modules/eks_cluster"
  cluster_name        = "voting-cluster"
  node_group_name     = "voting-node-group"
  subnet_ids          = module.network.public_subnet_ids
  cluster_role_arn    = data.aws_iam_role.lab_role.arn
  node_role_arn       = data.aws_iam_role.lab_role.arn
  ec2_ssh_key_name    = "voting-key-${terraform.workspace}" # Parametrizado por workspace
  instance_types      = ["t3.small"]
  desired_capacity    = 2
  min_capacity        = 1
  max_capacity        = 3
  tags                = var.tags
}


resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "voting_key" {
  key_name   = "voting-key-${terraform.workspace}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "${path.module}/voting-key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

# SNS Topic para alertas
resource "aws_sns_topic" "alerts" {
  name = "voting-app-alerts-${terraform.workspace}"
  
  tags = merge(var.tags, {
    Name = "voting-app-alerts-${terraform.workspace}"
    Environment = terraform.workspace
  })
}

# Suscripción por email al SNS Topic (opcional)
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Módulo Lambda Alerts
module "lambda_alerts" {
  source = "./modules/lambda-alerts"
  
  prefix       = "voting-app"
  sns_topic_arn = aws_sns_topic.alerts.arn
  lambda_src   = "${path.module}/modules/lambda-alerts/src/alert.py"
  
  # Configuración opcional
  timeout     = 30
  memory_size = 128
  log_retention_days = 7
  
  tags = merge(var.tags, {
    Environment = terraform.workspace
    Component   = "monitoring"
  })
}
