data "aws_caller_identity" "current" {}

# --- Buckets S3 ---
# Prod
resource "aws_s3_bucket" "prod" {
  bucket = "letterbox-movies-prod-2025"

  tags = { Name = "Letterbox Movies Prod", Environment = "prod" }
}

# Versionamiento
resource "aws_s3_bucket_versioning" "prod_versioning" {
  bucket = aws_s3_bucket.prod.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación
resource "aws_s3_bucket_server_side_encryption_configuration" "prod_sse" {
  bucket = aws_s3_bucket.prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Dev
resource "aws_s3_bucket" "dev" {
  bucket = "letterbox-movies-dev-2025"

  tags = { Name = "Letterbox Movies Dev", Environment = "dev" }
}

# Versionamiento
resource "aws_s3_bucket_versioning" "dev_versioning" {
  bucket = aws_s3_bucket.dev.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación
resource "aws_s3_bucket_server_side_encryption_configuration" "dev_sse" {
  bucket = aws_s3_bucket.dev.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Origin Access Control para CloudFront ---
# Prod OAC
resource "aws_cloudfront_origin_access_control" "prod_oac" {
  name                             = "prod-oac"
  description                      = "OAC para bucket prod"
  origin_access_control_origin_type = "s3"
  signing_behavior                 = "always"
  signing_protocol                 = "sigv4"
}

# Dev OAC
resource "aws_cloudfront_origin_access_control" "dev_oac" {
  name                             = "dev-oac"
  description                      = "OAC para bucket dev"
  origin_access_control_origin_type = "s3"
  signing_behavior                 = "always"
  signing_protocol                 = "sigv4"
}

# --- Distribución CloudFront ---
# Prod CDN
resource "aws_cloudfront_distribution" "prod_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.prod.bucket_regional_domain_name
    origin_id                = "prod-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.prod_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "prod-s3-origin"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Environment = "prod" }
}

# Dev CDN
resource "aws_cloudfront_distribution" "dev_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.dev.bucket_regional_domain_name
    origin_id                = "dev-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.dev_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "dev-s3-origin"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Environment = "dev" }
}


# Prod Policy
resource "aws_s3_bucket_policy" "prod_policy" {
  bucket = aws_s3_bucket.prod.id

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.prod.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.prod_cdn.arn
          }
        }
      }
    ]
  })
}


# Dev Policy
resource "aws_s3_bucket_policy" "dev_policy" {
  bucket = aws_s3_bucket.dev.id

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.dev.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.dev_cdn.arn
          }
        }
      }
    ]
  })
}
