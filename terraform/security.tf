# Step 1: Write the Application Load Balancer (ALB) Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Perimeter wall allowing public web traffic"
  vpc_id      = var.vpc_id # Assumes Vanrith defined this variable

  # Inbound: Allow HTTP from the internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: Allow HTTPS from the internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow traffic out to VPC subnets
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Step 2: Write the EC2 Web Server Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Shields web servers, restricting access strictly to the ALB"
  vpc_id      = var.vpc_id

  # Inbound: Allow app traffic ONLY from the ALB Security Group ID
  ingress {
    from_port       = 8080 # Adjust to Donal's specific application port if different
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Outbound: Allow EC2 to talk to the internet (for S3, CloudWatch, and updates)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Step 3: Write the RDS Database Security Group
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Isolates the database, restricting access strictly to the EC2 instances"
  vpc_id      = var.vpc_id

  # Inbound: Allow database traffic ONLY from the EC2 Security Group ID
  ingress {
    from_port       = 5432 # Default for PostgreSQL (change to 3306 if using MySQL)
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # Outbound: Isolated DBs typically don't need outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}
