# --- Availability Zones ---
# - state = "available" : solo trae Zonas disponibles
# - names : lista de nombres de las Zonas disponibles

data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC ---
# - cidr_block : CIDR block para la VPC
# - enable_dns_hostnames : habilita el DNS hostnames
# - enable_dns_support : habilita el DNS support
# - tags : tags para la VPC, ejemplo: Environment = "dev", Project = "voting-app"
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.tags["Project"]}-vpc"
  })
}

# --- Subnets públicas ---
# - count : cantidad de subnets públicas
# - vpc_id : ID de la VPC
# - cidr_block : CIDR block para la subnet
# - map_public_ip_on_launch : habilita el mapping de public IP
# - availability_zone : Availability Zone de la subnet
# - tags : tags para la subnet, ejemplo: Environment = "dev", Project = "voting-app"
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  map_public_ip_on_launch = true

  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(var.tags, {
    Name = "${var.tags["Project"]}-public-subnet-${count.index + 1}"
  })
}

# --- Internet Gateway ---
# - vpc_id : ID de la VPC
# - tags : tags para el Internet Gateway, ejemplo: Environment = "dev", Project = "voting-app"
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.tags["Project"]}-igw"
  })
}

# --- Route Table para tráfico público ---
# - vpc_id : ID de la VPC
# - route : ruta para el tráfico público, ejemplo: cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.igw.id
# - tags : tags para la Route Table, ejemplo: Environment = "dev", Project = "voting-app"
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.tags["Project"]}-public-rt"
  })
}

# --- Asociar cada subnet pública a la route table pública ---
# - count : cantidad de subnets públicas
# - subnet_id : ID de la subnet pública
# - route_table_id : ID de la Route Table
resource "aws_route_table_association" "public_rta" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}