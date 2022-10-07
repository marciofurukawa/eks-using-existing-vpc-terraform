resource "aws_s3_bucket" "buckets_lake" {
  count  = length(var.bucket_names)
  bucket = "${var.environment}-${var.project}-${var.bucket_names[count.index]}"
  acl    = "private"

  tags = var.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block_lake" {
  count  = length(var.bucket_names)
  bucket = "${var.environment}-${var.project}-${var.bucket_names[count.index]}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
