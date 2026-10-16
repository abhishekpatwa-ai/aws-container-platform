# ================= Platform values: har service ke liye SAME =================
# Network (week2), ALB (week3), cluster (week4), OIDC (week5) ki state se padhte hain.
# Ek baar yahan locals mein rakh diye, taaki har service file chhoti rahe.

locals {
  state_bucket = "abhishek-tfstate-7391"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config  = { bucket = local.state_bucket, key = "week2-network/terraform.tfstate", region = "eu-west-1" }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config  = { bucket = local.state_bucket, key = "week3-alb/terraform.tfstate", region = "eu-west-1" }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config  = { bucket = local.state_bucket, key = "week4-ecs/terraform.tfstate", region = "eu-west-1" }
}

data "terraform_remote_state" "cicd" {
  backend = "s3"
  config  = { bucket = local.state_bucket, key = "week5-cicd/terraform.tfstate", region = "eu-west-1" }
}

locals {
  platform = {
    cluster_name       = data.terraform_remote_state.ecs.outputs.cluster_name
    vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
    private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
    app_sg_id          = data.terraform_remote_state.network.outputs.app_sg_id
    listener_arn       = data.terraform_remote_state.alb.outputs.listener_arn
    oidc_provider_arn  = data.terraform_remote_state.cicd.outputs.oidc_provider_arn
  }
}
