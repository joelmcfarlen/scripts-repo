resource "aws_route53_record" "jenkins_dns_record" {
  depends_on = [aws_lb.jenkins_load_balancer]
  zone_id = var.hosted_zone_id
  name    = "jenkins.${var.hosted_zone_name}"
  type    = "A"

    alias {
    name                   = aws_lb.jenkins_load_balancer.dns_name
    zone_id                = aws_lb.jenkins_load_balancer.zone_id
    evaluate_target_health = true
  }
}




