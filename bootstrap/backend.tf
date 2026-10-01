terraform {
  backend "s3" {
    bucket       = "abhishek-tfstate-7391"
    key          = "bootstrap/terraform.tfstate"    # its own folder
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}