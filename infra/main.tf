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

provider "aws" {
  region  = var.aws_region
}

# ECR Repository
resource "aws_ecr_repository" "voting_app" {
  name                 = "voting-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
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

