resource "aws_ecr_repository" "nginx_bg" {
  name                 = "nginx-${var.environment}-bg"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "nginx_bg" {
  repository = aws_ecr_repository.nginx_bg.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}