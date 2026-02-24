# generate random password
resource "random_password" "db_password" {
  length  = 16
  special = true
  override_special = "!#$%&*"
}

# create secret
resource "aws_secretsmanager_secret" "db_secret" {
  name = "rds-mysql-credentials31"
}

# store username & password
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = "durvesh"
    password = random_password.db_password.result
  })
}

# read secret
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id  = aws_secretsmanager_secret.db_secret.id
  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}

# create security group for the database
resource "aws_security_group" "database_security_group" {
  name        = "database security group"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      = var.vpc_id

  ingress {
    description      = "mysql/aurora access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [var.alb_security_group_id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "database security group"
  }
}


# create the subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "db-secure-subnets"
  subnet_ids   = [var.secure_subnet_az1_id, var.secure_subnet_az2_id]
  description  = "rds in secure subnet"

  tags   = {
    Name = "db-secure-subnets"
  }
}


# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                  = "mysql"
  engine_version          = "8.4.7"
  multi_az                = true
  identifier              = "durveshy"
  username                = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["username"]
  password                = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["password"]
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  publicly_accessible     = false
  deletion_protection     = false
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.database_security_group.id]
  db_name                 = "app"
  skip_final_snapshot     = true
}
