##############
# CloudWatch
##############

data "aws_cloudwatch_log_groups" "gtp_uat_app_redis" {
  log_group_name_prefix = "/gtp/redis/logs"
}

resource "aws_cloudwatch_log_group" "gtp_uat_app_redis" {
  name = data.aws_cloudwatch_log_groups.gtp_uat_app_redis.log_group_name_prefix

  tags = {
    Environment = "Production"
    Application = "Redis"
  }
}

data "aws_cloudwatch_log_groups" "gtp_uat_app_nginx" {
  log_group_name_prefix = "/gtp/app/nginx/logs"
}

resource "aws_cloudwatch_log_group" "gtp_uat_app_nginx" {
  name = data.aws_cloudwatch_log_groups.gtp_uat_app_nginx.log_group_name_prefix

  tags = {
    Environment = "Production"
    Application = "nginx"
  }
}
