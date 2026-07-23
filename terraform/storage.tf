resource "aws_ssm_parameter" "db_password" {
  name  = "/rith-cloud-project/db-password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "main" {
  bucket_prefix = "rith-cloud-project-storage"
  force_destroy = true

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_db_instance" "main" {
  identifier             = "rith-cloud-db"
  engine                 = var.db_engine
  engine_version         = var.db_engine == "postgres" ? "16.3" : "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Project     = "Rith-Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
