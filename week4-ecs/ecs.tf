# ================= Lesson 4.3: ECS cluster + task definition =================

# ---------- Cluster: the factory building (on Fargate, just a logical group) ----------
resource "aws_ecs_cluster" "main" {
  name = "learning-cluster"
}

# ---------- Log group: where container stdout/stderr goes ----------
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/learning-app"
  retention_in_days = 7 # delete logs after 7 days (cost control)
}

# ---------- Task definition: the RECIPE ----------
resource "aws_ecs_task_definition" "app" {
  family                   = "learning-app" # revisions: learning-app:1, :2, :3...
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # every task gets its own ENI + private IP (required on Fargate)
  cpu                      = "256"    # 0.25 vCPU  (Fargate allows fixed CPU/memory pairs only)
  memory                   = "512"    # 512 MB

  execution_role_arn = aws_iam_role.execution.arn # hotel staff: pull image, write logs
  task_role_arn      = aws_iam_role.task.arn      # key card: the app's own AWS access (empty for now)

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "public.ecr.aws/docker/library/python:3.12-alpine" # ECR Public mirror of the official image
      essential = true                                               # if this container stops, the whole task stops

      # On start: write a page, then serve it on 8080 (same trick as Lesson 3.3)
      command = [
        "sh", "-c",
        "echo \"<h1>Hello from ECS Fargate task $(hostname)</h1>\" > /tmp/index.html && python -m http.server 8080 --directory /tmp"
      ]

      portMappings = [{
        containerPort = 8080 # matches app-sg and the target group
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs" # send stdout/stderr to CloudWatch Logs
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = "eu-west-1"
          awslogs-stream-prefix = "app" # stream name: app/app/<task-id>
        }
      }
    }
  ])
}
