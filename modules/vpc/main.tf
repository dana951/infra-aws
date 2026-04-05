locals {
  public_subnet_tags = merge(
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    },
    var.public_subnet_tags,
  )

  private_subnet_tags = merge(
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    },
    var.private_subnet_tags,
  )
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
      Name = "${var.name_prefix}-vpc"
    },
  )
}

resource "aws_internet_gateway" "aws_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-igw"
    },
  )
}

resource "aws_subnet" "public_subnet" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.common_tags,
    local.public_subnet_tags,
    {
      Name = "${var.name_prefix}-public_subnet-${each.key}"
    },
  )
}

resource "aws_subnet" "private_subnet" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(
    var.common_tags,
    local.private_subnet_tags,
    {
      Name = "${var.name_prefix}-private_subnet-${each.key}"
    },
  )
}

resource "aws_eip" "eip" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-eip"
    },
  )

  depends_on = [aws_internet_gateway.aws_igw]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet[var.nat_gateway_public_subnet_key].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-nat"
    },
  )

  depends_on = [aws_internet_gateway.aws_igw]
}

# Default IPv4 egress for public subnets: 0.0.0.0/0 via Internet Gateway.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_igw.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-public-rt"
    },
  )
}

resource "aws_route_table_association" "public_subnet_rt_association" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_rt.id
}

# Default IPv4 egress for private subnets: 0.0.0.0/0 via NAT Gateway (single NAT).
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-private-rt"
    },
  )
}

resource "aws_route_table_association" "private_subnet_rt_association" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_rt.id
}
