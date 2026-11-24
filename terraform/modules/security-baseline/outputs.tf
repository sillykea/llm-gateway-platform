output "audit_bucket" {
  value = aws_s3_bucket.audit.bucket
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.this.id
}
