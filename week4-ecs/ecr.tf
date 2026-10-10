resource "aws_ecr_repository" "app" {
  name                 = "learning-app"
  image_tag_mutability = "IMMUTABLE" # 🤔 इसका मतलब क्या है? (नीचे सवाल देख)
  force_delete         = true        # learning के लिए: destroy करते समय images भी delete हो जाएँ

  image_scanning_configuration {
    scan_on_push = true # हर push पर CVE scan (तेरे Twistlock वाले काम जैसा!)
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}