resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
    Name        = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
    Name        = "private-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
    Name        = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
    Name        = "private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_db_subnet_group" "main" {
  name       = "rith-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
