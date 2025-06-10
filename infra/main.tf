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

# ECR Repositories
module "ecr_vote" {
  source = "./modules/ecr-repo"
  name   = "voting-app-vote"
  tags   = var.tags
}

module "ecr_result" {
  source = "./modules/ecr-repo"
  name   = "voting-app-result"
  tags   = var.tags
}

module "ecr_seed" {
  source = "./modules/ecr-repo"
  name   = "voting-app-seed"
  tags   = var.tags
}

module "ecr_worker" {
  source = "./modules/ecr-repo"
  name   = "voting-app-worker"
  tags   = var.tags
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

