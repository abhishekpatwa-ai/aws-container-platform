output "bucket_arn" {
  description = "ARN of the learning bucket"
  value       = aws_s3_bucket.first.arn
}