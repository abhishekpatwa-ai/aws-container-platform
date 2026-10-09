# ================= Lesson 3.2: Application Load Balancer =================
#
#   Internet ──► ALB (public subnets, alb-sg) ──► Listener :80 ──► Target group ──► App :8080 (private)

# ---------- 1. The load balancer (the "reception building") ----------
resource "aws_lb" "main" {
  name               = "learning-alb"
  load_balancer_type = "application"                                                 # ALB = Layer 7 (HTTP)
  internal           = false                                                         # internet-facing → needs PUBLIC subnets
  security_groups    = [data.terraform_remote_state.network.outputs.alb_sg_id]       # a string, so wrap it in [ ]
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids # already a list (2 AZs)

  drop_invalid_header_fields = true # security best practice: reject malformed headers

  tags = { Name = "learning-alb" }
}

# ---------- 2. Target group (the "doctor list" + health check) ----------
resource "aws_lb_target_group" "app" {
  name        = "learning-app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  target_type = "ip" # Fargate tasks have no instance ID, only an IP (Friday!)

  deregistration_delay = 30 # default 300s; wait 30s for in-flight requests before removing a target

  health_check {
    path                = "/"
    matcher             = "200" # only HTTP 200 = healthy
    interval            = 15    # check every 15 seconds
    healthy_threshold   = 2     # 2 passes in a row  → healthy
    unhealthy_threshold = 3     # 3 failures in a row → unhealthy (~45s to detect)
    timeout             = 5
  }

  tags = { Name = "learning-app-tg" }
}

# ---------- 3. Listener (the "reception window" on port 80) ----------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn # same folder → resource address; attribute is "arn"
  port              = 80
  protocol          = "HTTP"

  # Production: a 443 listener with an ACM certificate, and port 80 redirecting to 443.
  # We have no domain/certificate, so we forward plain HTTP.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn # our resource is named "app", not "main"
  }
}
