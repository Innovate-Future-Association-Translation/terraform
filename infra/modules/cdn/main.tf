

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
}

# S3 bucket for static content
resource "aws_s3_bucket" "static_site" {
  bucket = replace(var.student_subdomain, ".", "-")
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload sample index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "index.html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<body>
<h1>Hello from ${var.student_subdomain}!</h1>
<p>Content version: ${var.content_version}</p>
</body>
</html>
EOF
  content_type = "text/html"
}

# ACM Certificate
resource "aws_acm_certificate" "cert" {
  # Request certificate for both specific and wildcard domains
  domain_name               = var.student_subdomain
  subject_alternative_names = ["*.${var.student_subdomain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront origin access control
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "OAC ${var.student_subdomain}"
  description                       = "Origin Access Control for Static Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 bucket policy document
data "aws_iam_policy_document" "static_site" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.static_site.json
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.student_subdomain]

  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3Origin"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# CloudFront DNS record (CNAME)
resource "aws_route53_record" "cdn_alias" {
  zone_id = var.hosted_zone_id
  name    = var.student_subdomain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}