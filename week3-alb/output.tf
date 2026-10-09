output "test_vpc_id" {
  value = data.terraform_remote_state.network.outputs.vpc_id # "outputs" — plural
}

output "test_alb_sg_id" {
  value = data.terraform_remote_state.network.outputs.alb_sg_id
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name # attribute of aws_lb is "dns_name"
}

output "alb_url" {
  value = "http://${aws_lb.main.dns_name}" # open this in the browser
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn # needed in Lesson 3.3 to register the server
}
