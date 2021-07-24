# ssl証明書のリクエスト
resource "aws_acm_certificate" "svg_portfolio" {
  domain_name = "www.hirabayashi.work"
  # domain_nameとは別に追加したいドメイン名がある場合は記入する。なければ空配列。
  subject_alternative_names = []
  validation_method = "DNS"

  tags = {
    Name = "svg_portfolio-acm"
  }

  lifecycle {
    # 既存のリソースを削除してから新たなリソースを作成するのではなく、
    # 新たなリソースを作成してから既存のリソースを削除する。
    # こうすることでSSL証明書の再作成時のサービス影響を最小化する。
    create_before_destroy = true
  }
}

# 検証用DNSレコード
resource "aws_route53_record" "svg_portfolio_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.svg_portfolio.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  # hirabayahsi.workのホストゾーンID(ブラウザのRoute53から確認)
  zone_id = "Z04693571HENT1MQSKK18"
}

# 検証の待機
resource "aws_acm_certificate_validation" "svg_portfolio" {
  certificate_arn = aws_acm_certificate.svg_portfolio.arn
  validation_record_fqdns = [ for record in aws_route53_record.svg_portfolio_certificate : record.fqdn ]
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
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    # 成功したときのレスポンスコード
    matcher = 200
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
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    # 成功したときのレスポンスコード
    matcher = 200
    # ヘルスチェックで使用されるポート。traffic-portにした場合、指定されているポートになる(80)。
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
