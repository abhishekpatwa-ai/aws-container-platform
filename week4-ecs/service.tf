# ================= Lesson 4.4: ECS service behind the ALB =================
#
#   ALB (week 3) → target group (ip) → 2 Fargate tasks in private-a and private-b (app-sg, :8080)

resource "aws_ecs_service" "app" {
  name            = "learning-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn # points at a specific revision (learning-app:1)
  desired_count   = 2                               # the supervisor keeps 2 tasks running at all times
  launch_type     = "FARGATE"

  # awsvpc: each task gets its own ENI in a PRIVATE subnet with app-sg (8080 only from alb-sg)
  network_configuration {
    subnets          = data.terraform_remote_state.network.outputs.private_subnet_ids # 2 AZs → tasks spread across both
    security_groups  = [data.terraform_remote_state.network.outputs.app_sg_id]
    assign_public_ip = false # private: image pulls and logs go out via NAT
  }

  # Register every task's IP:8080 into week 3's target group automatically
  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.target_group_arn
    container_name   = "app" # must match the name in container_definitions
    container_port   = 8080
  }

  # Ignore ALB health checks for the first 30s while the container boots
  health_check_grace_period_seconds = 30

  # Rolling deployment: keep 100% healthy, allow up to 200% during a deploy (2 old + 2 new)
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # If new tasks keep failing, stop the deployment and roll back to the last working revision
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # terraform apply waits until the service is stable (tasks running + healthy)
  wait_for_steady_state = true

  # Auto scaling (autoscaling.tf) changes desired_count at runtime.
  # Without this, every terraform apply would reset it back to 2.
  lifecycle {
    ignore_changes = [desired_count]
  }
}
