# module "redis_sg" {
#   source = "./security_group"
#   name = "redis-sg"
#   vpc_id = aws_vpc.hair_salon_bayashi.id
#   port = 6379
#   cidr_blocks = [aws_vpc.hair_salon_bayashi.cidr_block]
# }

# # ElastiCacheパラメータグループの定義
# resource "aws_elasticache_parameter_group" "hair_salon_bayashi" {
#   name = "hair_salon_bayashi"
#   family = "redis5.0"

#   parameter {
#     # クラスターモード無効
#     name = "cluster-enabled"
#     value = "no"
#   }
# }

# # ElastiCacheサブネットグループの定義
# resource "aws_elasticache_subnet_group" "hair_salon_bayashi" {
#   name = "hair_salon_bayashi"
#   subnet_ids = [ aws_subnet.private_0.id, aws_subnet.private_1.id ]
# }

# # ElastiCacheレプリケーショングループの定義
# resource "aws_elasticache_replication_group" "hair_salon_bayashi" {
#   # Redisのエンドポイントで使う識別子
#   replication_group_id = "hair_salon_bayashi"
#   replication_group_description = "Cluster Disabled"
#   engine = "redis"
#   engine_version = "5.0.4"
#   # プライマリノードとレプリカノードの合計値。2ならプライマリ1、レプリカ1になる。
#   number_cache_clusters = 2
#   node_type = "cache.m3.medium"
#   # 障害が起きた時自動フェイルオーバーによって運用を維持する。マルチAZしていることが前提。
#   automatic_failover_enabled = true
#   port = 6379
#   security_group_ids = [module.redis_sg.security_group_id]
#   parameter_group_name = aws_elasticache_parameter_group.hair_salon_bayashi.name
#   subnet_group_name = aws_elasticache_subnet_group.hair_salon_bayashi.name
# }