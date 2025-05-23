terraform {
  backend "s3" {
    bucket         = "voting-app-terraform-state-177816"
    key            = "voting-app/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
