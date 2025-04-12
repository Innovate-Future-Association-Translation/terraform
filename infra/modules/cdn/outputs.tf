output "certificate_validation_records" {
  description = "DNS records for certificate validation (provide these to instructor)"
  value = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (provide to instructor)"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "website_url" {
  description = "Website URL (once instructor adds CNAME)"
  value       = "https://${var.student_subdomain}"
}