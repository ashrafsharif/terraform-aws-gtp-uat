#####################
# ElastiCache Redis
#####################

resource "aws_elasticache_subnet_group" "gtp_uat_redis" {
  name       = "gtp-uat-redis"
  subnet_ids = [data.aws_subnets.private.ids[0]]

  tags = {
    Name = "Redis Elasticache subnet group for UAT"
  }
}

resource "aws_elasticache_cluster" "gtp_uat_redis" {
  cluster_id                 = "gtp-uat-redis"
  engine                     = "redis"
  engine_version             = "6.2"
  node_type                  = "cache.t4g.small" # Real UAT: "cache.r6g.large"
  num_cache_nodes            = 1
  parameter_group_name       = "default.redis6.x"
  apply_immediately          = true
  auto_minor_version_upgrade = false
  subnet_group_name          = aws_elasticache_subnet_group.gtp_uat_redis.name
  maintenance_window         = "sat:21:01-sat:23:00" # 9 PM UTC = 5 AM MYT
  snapshot_window            = "20:00-21:00"         # 8 PM UTC = 4 AM MYT
  snapshot_retention_limit   = 7
  port                       = 6379
  security_group_ids         = [aws_security_group.gtp_uat_redis.id]

  tags = {
    Tier = "Database"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.gtp_uat_app_redis.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }
}
