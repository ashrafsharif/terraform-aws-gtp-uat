output "vpc_id" {
  value = data.aws_vpc.target_vpc.id
}

output "app_name" {
  value = aws_codedeploy_app.gtp_uat_app.name
}

output "mysql_rds_endpoint" {
  value = aws_db_instance.gtp_uat_mysql.endpoint
}

output "app_endpoint" {
  value = aws_lb.gtp_uat_app.dns_name
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.gtp_uat_redis.cache_nodes
}
