data "terraform_remote_state" "network" {
  backend = "s3" # where is week 2's state stored?

  config = {
    bucket = "abhishek-tfstate-7391"           # same bucket as in backend.tf
    key    = "week2-network/terraform.tfstate" # WEEK 2's key (not week 3's!)
    region = "eu-west-1"
  }
}