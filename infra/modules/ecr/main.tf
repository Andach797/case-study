resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_scanning_configuration { scan_on_push = var.image_scan_on_push }
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags
}

resource "aws_ecr_lifecycle_policy" "clean_old" {
  repository = aws_ecr_repository.this.name
  policy     = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last N images"
      selection    = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = var.max_images
      }
      action = { type = "expire" }
    }]
  })
}
