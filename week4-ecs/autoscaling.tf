# ================= Lesson 4.5: ECS Service Auto Scaling (like Kubernetes HPA) =================
#
#   CloudWatch metric (average CPU of the service) ──► target tracking policy ──► desired_count 2..4

# ---------- 1. Scalable target: WHAT can scale, and between which limits ----------
resource "aws_appautoscaling_target" "app" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}" # service/learning-cluster/learning-app
  scalable_dimension = "ecs:service:DesiredCount"                                        # we scale the NUMBER of tasks (horizontal)
  min_capacity       = 2                                                                 # never fewer than 2 (one per AZ)
  max_capacity       = 4                                                                 # cost ceiling
}

# ---------- 2. Policy: HOW to scale → keep average CPU around 60% ----------
resource "aws_appautoscaling_policy" "cpu" {
  name               = "learning-app-cpu-60"
  policy_type        = "TargetTrackingScaling" # like a thermostat: AWS adds/removes tasks to hold the target
  service_namespace  = aws_appautoscaling_target.app.service_namespace
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60  # aim for 60% average CPU across tasks
    scale_out_cooldown = 60  # after adding tasks, wait 60s before adding more
    scale_in_cooldown  = 120 # remove tasks more slowly than we add them (avoid flapping)
  }
}
