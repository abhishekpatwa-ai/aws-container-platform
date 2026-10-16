# ================= Shared ECS cluster (platform) =================
#
# Cluster = sab services ka logical group (Fargate par koi server nahi).
# Services yahan nahi bante: har service modules/ecs-service se services/ folder mein banti hai.

resource "aws_ecs_cluster" "main" {
  name = "learning-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" # CPU/memory/task metrics CloudWatch mein (per service, per task)
  }
}
