# http通信用セキュリティーグループ
module "http_sg" {
  source = "./security_group"
  name = "http-sg"
  vpc_id = aws_vpc.hair_salon_bayashi.id
  port = 80
  cidr_blocks = ["0.0.0.0/0"]
}

# https通信用セキュリティーグループ
module "https_sg" {
  source = "./security_group"
  name = "https-sg"
  vpc_id = aws_vpc.hair_salon_bayashi.id
  port = 443
  cidr_blocks = ["0.0.0.0/0"]
}

# api用セキュリティーグループ
module "https_api_sg" {
  source = "./security_group"
  name = "https-api-sg"
  vpc_id = aws_vpc.hair_salon_bayashi.id
  port = 3000
  cidr_blocks = ["0.0.0.0/0"]
}

# アプリケーションロードバランサー
resource "aws_lb" "hair_salon_bayashi" {
  name = "hair-salon-bayashi"
  load_balancer_type = "application"
  # インターネット向けか内部向けか。falseならインターネット向け。
  internal = false
  idle_timeout = 60
  # trueの場合、ロードバランサーの削除はAWSAPIを介して無効になります。
  # これにより、Terraformがロードバランサーを削除できなくなります。
  # enable_deletion_protection = true

  subnets = [ 
    aws_subnet.public.id,
    aws_subnet.public_other.id,
  ]

  access_logs {
    bucket = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [ 
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.https_api_sg.security_group_id
  ]
}

output "alb_dns_name" {
  value = aws_lb.hair_salon_bayashi.dns_name
}