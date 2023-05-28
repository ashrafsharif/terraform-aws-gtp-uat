##############
# CloudWatch
##############

data "aws_cloudwatch_log_groups" "gtp_uat_app_redis" {
  log_group_name_prefix = "/gtp/redis/logs"
}

resource "aws_cloudwatch_log_group" "gtp_uat_app_redis" {
  name = data.aws_cloudwatch_log_groups.gtp_uat_app_redis.log_group_name_prefix

  tags = {
    Environment = "UAT"
    Application = "Redis"
  }
}

data "aws_cloudwatch_log_groups" "gtp_uat_app_nginx" {
  log_group_name_prefix = "/gtp/app/nginx/logs"
}

resource "aws_cloudwatch_log_group" "gtp_uat_app_nginx" {
  name = data.aws_cloudwatch_log_groups.gtp_uat_app_nginx.log_group_name_prefix

  tags = {
    Environment = "UAT"
    Application = "nginx"
  }
}

data "aws_cloudwatch_log_groups" "gtp_uat_app_snap" {
  log_group_name_prefix = "/gtp/app/snap/logs"
}

resource "aws_cloudwatch_log_group" "gtp_uat_app_snap" {
  name = data.aws_cloudwatch_log_groups.gtp_uat_app_snap.log_group_name_prefix

  tags = {
    Environment = "UAT"
    Application = "snap"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_cloudwatch_log_groups" "gtp_uat_app_php" {
  log_group_name_prefix = "/gtp/app/php/logs"
}

resource "aws_cloudwatch_log_group" "gtp_uat_app_php" {
  name = data.aws_cloudwatch_log_groups.gtp_uat_app_php.log_group_name_prefix

  tags = {
    Environment = "UAT"
    Application = "php"
  }
}

data "aws_cloudwatch_log_groups" "gtp_uat_app_cron" {
  log_group_name_prefix = "/gtp/app/cron/logs"
}

resource "aws_cloudwatch_log_group" "gtp_uat_app_cron" {
  name = data.aws_cloudwatch_log_groups.gtp_uat_app_cron.log_group_name_prefix

  tags = {
    Environment = "UAT"
    Application = "cron"
  }
}
