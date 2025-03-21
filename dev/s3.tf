resource "aws_s3_bucket" "codedeploy_bucket" {
  bucket = var.docker_image_bucket_name
}

resource "aws_s3_bucket_policy" "codedeploy_bucket_policy" {
  bucket = aws_s3_bucket.codedeploy_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.codedeploy_ec2_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.codedeploy_bucket.arn}/*"
      }
    ]
  })
}
