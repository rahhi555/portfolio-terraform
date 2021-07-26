# http及びhttps用のドメイン紐付け
resource "aws_route53_record" "http_https" {
  zone_id = "Z04693571HENT1MQSKK18"
  name = "www"
  type = "A"

  alias {
    name = aws_lb.svg_portfolio.dns_name
    zone_id = aws_lb.svg_portfolio.zone_id
    evaluate_target_health = false
  }
}

output "route53_http" {
  value = aws_route53_record.http_https.name
}