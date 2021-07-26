# http通信用セキュリティーグループ
module "http_sg" {
  source = "./security_group"
  name = "http-sg"
  vpc_id = aws_vpc.svg_portfolio.id
  port = 80
  cidr_blocks = ["0.0.0.0/0"]
}

# https通信用セキュリティーグループ
module "https_sg" {
  source = "./security_group"
  name = "https-sg"
  vpc_id = aws_vpc.svg_portfolio.id
  port = 443
  cidr_blocks = ["0.0.0.0/0"]
}

# api用セキュリティーグループ
module "https_api_sg" {
  source = "./security_group"
  name = "https-api-sg"
  vpc_id = aws_vpc.svg_portfolio.id
  port = 3000
  cidr_blocks = ["0.0.0.0/0"]
}

# アプリケーションロードバランサー
resource "aws_lb" "svg_portfolio" {
  name = "svg-portfolio"
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
  value = aws_lb.svg_portfolio.dns_name
}

###############    front側のリスナー及びターゲットグループの設定    #################

# albのhttps用リスナー
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.svg_portfolio.arn
  port = "443"
  protocol = "HTTPS"
  certificate_arn = aws_acm_certificate.svg_portfolio.arn
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これはHTTPSです"
      status_code = "200"
    }
  }
}

# httpからhttpsにリダイレクトするリスナー
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.svg_portfolio.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "svg_portfolio" {
  name = "svg-portfolio"
  target_type = "ip"
  vpc_id = aws_vpc.svg_portfolio.id
  port = 80
  protocol = "HTTP"
  deregistration_delay = 300

  health_check {
    path = "/server/health-check"
    # 正常のしきい値 この回数分連続でヘルスチェックに成功すれば正常とみなされる
    healthy_threshold = 5
    # 非正常のしきい値　この回数分連続でヘルスチェックに失敗すると異常とみなされる
    unhealthy_threshold = 5
    timeout = 20
    interval = 30
    # 成功したときのレスポンスコード
    matcher = "200,304"
    # ヘルスチェックで使用されるポート。traffic-portにした場合、指定されているポートになる(80)。
    port = "traffic-port"
    protocol = "HTTP"
  }
  # 依存関係を明示する
  depends_on = [aws_lb.svg_portfolio]
  
  tags = {
    Name = "svg_portfolio-alb-target"
  }
}

# ターゲットグループにリクエストをフォワードするリスナールール
resource "aws_lb_listener_rule" "svg_portfolio" {
  listener_arn = aws_lb_listener.https.arn
  priority = 99

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.svg_portfolio.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}


###############    api側のリスナー及びターゲットグループの設定    ################

# albのapi用リスナー(frontをhttpsにしているので、api側もhttpsにしないとmixed contentエラーが発生する)
resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.svg_portfolio.arn
  port = "3000"
  protocol = "HTTPS"
  certificate_arn = aws_acm_certificate.svg_portfolio.arn
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これはHTTPSかつapiです"
      status_code = "200"
    }
  }
}

# ターゲットグループ(api)
resource "aws_lb_target_group" "svg_portfolio_api" {
  name = "svg-portfolio-api"
  target_type = "ip"
  vpc_id = aws_vpc.svg_portfolio.id
  port = 3000
  protocol = "HTTP"
  deregistration_delay = 300

  health_check {
    path = "/health-check"
    # 正常のしきい値 この回数分連続でヘルスチェックに成功すれば正常とみなされる
    healthy_threshold = 5
    # 非正常のしきい値　この回数分連続でヘルスチェックに失敗すると異常とみなされる
    unhealthy_threshold = 5
    timeout = 20
    interval = 30
    # 成功したときのレスポンスコード
    matcher = 200
    # ヘルスチェックで使用されるポート。traffic-portにした場合、指定されているポートになる(3000)。
    port = "traffic-port"
    protocol = "HTTP"
  }
  # 依存関係を明示する
  depends_on = [aws_lb.svg_portfolio]
  
  tags = {
    Name = "svg_portfolio-alb-api-target"
  }
}

# ターゲットグループにリクエストをフォワードするリスナールール(api)
resource "aws_lb_listener_rule" "svg_portfolio_api" {
  listener_arn = aws_lb_listener.api.arn
  priority = 98

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.svg_portfolio_api.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
