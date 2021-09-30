module "redis_sg" {
  source = "./security_group"
  name = "redis-sg"
  vpc_id = aws_vpc.svg_portfolio.id
  port = 6379
  cidr_blocks = [aws_vpc.svg_portfolio.cidr_block]
}

# ElastiCacheパラメータグループの定義
resource "aws_elasticache_parameter_group" "svg_portfolio" {
  name = "svg-portfolio"
  family = "redis6.x"

  parameter {
    # クラスターモード無効
    name = "cluster-enabled"
    value = "no"
  }
}

# ElastiCacheサブネットグループの定義
resource "aws_elasticache_subnet_group" "svg_portfolio" {
  name = "svg-portfolio"
  subnet_ids = [ aws_subnet.private.id, aws_subnet.private_other.id ]
}

# ElastiCacheレプリケーショングループの定義
resource "aws_elasticache_replication_group" "svg_portfolio" {
  # Redisのエンドポイントで使う識別子
  replication_group_id = "svg-portfolio"
  replication_group_description = "Cluster Disabled"
  engine = "redis"
  engine_version = "6.x"
  # プライマリノードとレプリカノードの合計値。2ならプライマリ1、レプリカ1になる。
  number_cache_clusters = 1
  node_type = "cache.t2.small"
  # 障害が起きた時自動フェイルオーバーによって運用を維持する。マルチAZしていることが前提。
  automatic_failover_enabled = false
  port = 6379
  security_group_ids = [module.redis_sg.security_group_id]
  parameter_group_name = aws_elasticache_parameter_group.svg_portfolio.name
  subnet_group_name = aws_elasticache_subnet_group.svg_portfolio.name
}