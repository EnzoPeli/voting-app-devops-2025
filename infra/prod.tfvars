aws_region  = "us-east-1"
aws_profile = "default"

vpc_cidr = "10.0.0.0/16"

public_subnets_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

tags = {
  Environment = "prod"
  Project     = "voting-app"
}