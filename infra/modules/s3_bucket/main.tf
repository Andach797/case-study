resource "aws_s3_bucket" "this" {
  bucket = var.name
  force_destroy = var.force_destroy
  tags = var.tags
}

# TODO: Block public access for now.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle for transition all objects to glacier after n days
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "glacier-transition"
    status = "Enabled"

    transition {
      days          = var.days_to_glacier
      storage_class = "GLACIER"
    }
  }
}
