#############################
# RDS MySQL single instance
#############################

resource "aws_db_subnet_group" "gtp_uat_mysql" {
  name       = "gtp-uat-mysql"
  subnet_ids = [data.aws_subnets.protected.ids[0], data.aws_subnets.protected.ids[1]]

  tags = {
    Name = "MySQL RDS subnet group for UAT"
  }
}

resource "aws_db_instance" "gtp_uat_mysql" {
  engine                          = "mysql"
  identifier                      = "gtpuatmysql"
  allocated_storage               = 5 # Real UAT: 200
  engine_version                  = "8.0.32"
  instance_class                  = "db.t3.micro" # Real prod: db.m5d.xlarge
  port                            = 3306
  username                        = var.mysql_admin_user
  password                        = var.mysql_admin_password
  parameter_group_name            = "default.mysql8.0"
  backup_window                   = "18:00-23:00"
  backup_retention_period         = 7
  db_subnet_group_name            = aws_db_subnet_group.gtp_uat_mysql.name
  vpc_security_group_ids          = [aws_security_group.gtp_uat_mysql.id]
  skip_final_snapshot             = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  publicly_accessible             = false
  tags = {
    Tier = "Database"
  }
}
