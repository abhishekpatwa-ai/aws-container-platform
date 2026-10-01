terraform {
  backend "s3" {
    bucket       = "abhishek-tfstate-7391"                  # the bucket you just created
    key          = "week1-first-bucket/terraform.tfstate"   # path inside the bucket
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true                                     # S3 native locking
  }
}