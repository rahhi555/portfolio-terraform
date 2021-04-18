# resource "aws_service_discovery_private_dns_namespace" "web" {
#   name = "web"
#   description = "web service discovery dns namespace!!"
#   vpc = aws_vpc.hair_salon_bayashi.id
# }

# resource "aws_service_discovery_service" "web" {
#   name = "web-service-discovery"

#   dns_config {
#     namespace_id = aws_service_discovery_private_dns_namespace.web.id

#     dns_records {
#       ttl = 10
#       type = "A"
#     }

#     routing_policy = "MULTIVALUE"
#   }
# }