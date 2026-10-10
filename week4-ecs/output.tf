output "service_name" {
  value = aws_ecs_service.app.name
}

output "alb_url" {
  value = data.terraform_remote_state.alb.outputs.alb_url # open this in the browser
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url # 🤔 aws_ecr_repository का कौन-सा attribute? (Registry → Attribute Reference)
}