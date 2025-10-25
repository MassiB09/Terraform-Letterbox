# --- Identity Provider (si todavía no existe en tu cuenta) ---
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub oficial
}

# --- IAM Policy Prod ---
resource "aws_iam_policy" "movies_letterbox_prod_policy" {
  name        = "Movies-letterbox-Prod-Policy"
  description = "Permisos para invalidar CloudFront y escribir en el bucket S3 de movies-letterbox-prod"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::letterbox-movies-prod-2025",
          "arn:aws:s3:::letterbox-movies-prod-2025/*"
        ]
      },
      {
        Sid      = "InvalidateCF"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.prod_cdn.arn
      }
    ]
  })
}


# --- IAM Role para GitHub Actions ---
resource "aws_iam_role" "movies_letterbox_prod_role" {
  name = "Movies-letterbox-Prod"

  # Relación de confianza con GitHub Actions
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # Solo repositorios específicos pueden asumir el rol
            "token.actions.githubusercontent.com:sub" = "repo:movies-letterboxd/letterboxd-movies-front:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# --- Vincular Policy al Role ---
resource "aws_iam_role_policy_attachment" "movies_letterbox_prod_attach" {
  role       = aws_iam_role.movies_letterbox_prod_role.name
  policy_arn = aws_iam_policy.movies_letterbox_prod_policy.arn
}


# --- IAM Policy personalizada para entorno DEV ---
resource "aws_iam_policy" "movies_letterbox_front_dev_policy" {
  name        = "Movies-letterbox-Front-Dev-Policy"
  description = "Permisos para escribir en el bucket S3 de movies-letterbox-dev y crear invalidaciones en CloudFront (dev)"

policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::letterbox-movies-dev-2025",
          "arn:aws:s3:::letterbox-movies-dev-2025/*"
        ]
      },
      {
        Sid      = "InvalidateCF"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.dev_cdn.arn
      }
    ]
  })
}

# --- IAM Role para GitHub Actions (entorno DEV) ---
resource "aws_iam_role" "movies_letterbox_front_dev_role" {
  name = "Movies-letterbox-Front-Dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:movies-letterboxd/letterboxd-movies-front:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# --- Vincular Policy al Role ---
resource "aws_iam_role_policy_attachment" "movies_letterbox_front_dev_attach" {
  role       = aws_iam_role.movies_letterbox_front_dev_role.name
  policy_arn = aws_iam_policy.movies_letterbox_front_dev_policy.arn
}
