variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used when naming all resources"
  type        = string
  default     = "varnisha"
}

variable "instance_type" {
  description = "EC2 instance type running MongoDB + the Express API + both Next.js apps"
  type        = string
  default     = "t3.medium"
}

variable "ssh_public_key" {
  description = "Public half of the shared deploy SSH keypair (ssh-keygen -t ed25519). The private half is used both for your own SSH access and as the GitHub Actions deploy secret in all 3 app repos."
  type        = string
}

variable "uploads_bucket_name" {
  description = "Globally-unique S3 bucket name for public product/category/collection/look/blog/social image uploads"
  type        = string
}

variable "backups_bucket_name" {
  description = "Globally-unique S3 bucket name for private mongodump backups (30-day lifecycle expiry)"
  type        = string
}
