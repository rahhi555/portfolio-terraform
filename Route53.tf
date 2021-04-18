# お名前ドットコムでドメイン購入済み
# http及びhttps用のドメイン紐付け
resource "aws_route53_record" "http_https" {
  zone_id = "Z04693571HENT1MQSKK18"
  name = "www"
  type = "A"

  alias {
    name = aws_lb.hair_salon_bayashi.dns_name
    zone_id = aws_lb.hair_salon_bayashi.zone_id
    evaluate_target_health = false
  }
}

output "route53_http" {
  value = aws_route53_record.http_https.name
}