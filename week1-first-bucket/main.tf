resource "aws_s3_bucket" "first" {
  bucket = var.bucket_name            # value comes from terraform.tfvars

  tags = {
    Purpose = "first-lesson"
    Lesson  = "1-3-lock-demo"
  }
}

resource "aws_s3_bucket_versioning" "first" {
  bucket = aws_s3_bucket.first.id     # ← reference to the bucket above

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "first" {
  bucket = aws_s3_bucket.first.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"         # SSE-S3: AWS-managed keys
    }
  }
}

resource "aws_s3_bucket_public_access_block" "first" {
  bucket = aws_s3_bucket.first.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}