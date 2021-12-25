# ssl証明書のリクエスト
resource "aws_acm_certificate" "svg_portfolio" {
  domain_name = "www.minimap.work"
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
  zone_id = aws_route53_zone.svg_portfolio_route53_zone.zone_id
}

# 検証の待機
resource "aws_acm_certificate_validation" "svg_portfolio" {
  certificate_arn = aws_acm_certificate.svg_portfolio.arn
  validation_record_fqdns = [ for record in aws_route53_record.svg_portfolio_certificate : record.fqdn ]
}

