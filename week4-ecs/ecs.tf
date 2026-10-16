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

# ---------- ECR scanning: account (registry) level, sab repos ke liye ----------
# Registry-level config ho to repo ka scan_on_push ignore hota hai, isliye rule yahan lagta hai.
# Golden pipeline isi scan ke result par CRITICAL milne par deploy rokti hai.
resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}
