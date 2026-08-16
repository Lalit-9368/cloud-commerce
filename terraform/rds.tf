# ============================================================
# Phase 7.2 - RDS PostgreSQL Multi-AZ
# ============================================================

resource "aws_db_subnet_group" "postgres" {
  name        = "${var.project_name}-${var.environment}-postgres"
  description = "Private subnet group for Cloud Commerce PostgreSQL"
  subnet_ids  = module.vpc.private_subnets

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${var.project_name}-${var.environment}-postgres"
  family      = "postgres17"
  description = "PostgreSQL parameter group for Cloud Commerce"

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "17"

  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "cloudcommerce"
  username = "cloudcommerce"

  manage_master_user_password = true

  multi_az = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  parameter_group_name   = aws_db_parameter_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  auto_minor_version_upgrade = true

  deletion_protection = false
  skip_final_snapshot = true

  copy_tags_to_snapshot = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
