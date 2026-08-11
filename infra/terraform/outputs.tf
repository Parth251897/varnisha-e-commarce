output "elastic_ip" {
  description = "Public IP — point the api./www./laxmi. A records at this in GoDaddy"
  value       = aws_eip.app.public_ip
}

output "uploads_bucket_name" {
  description = "Set as S3_BUCKET_NAME in the backend's production .env"
  value       = aws_s3_bucket.uploads.bucket
}

output "backups_bucket_name" {
  description = "mongodump cron destination"
  value       = aws_s3_bucket.backups.bucket
}

output "ssh_command" {
  description = "Run this to SSH into the box for the one-time manual setup"
  value       = "ssh -i <path-to-your-private-deploy-key> ubuntu@${aws_eip.app.public_ip}"
}
