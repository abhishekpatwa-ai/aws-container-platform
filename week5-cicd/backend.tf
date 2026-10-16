terraform {
  backend "s3" {
    bucket       = "abhishek-tfstate-7391"
    key          = "week5-cicd/terraform.tfstate" # new project → new key
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}