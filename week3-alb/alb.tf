# ================= Shared ALB (platform) =================
#
#   Internet ──► ALB (public subnets, alb-sg) ──► Listener :80
#                                                   ├─ rule /api/*  ──► uconia-api target group   (modules/ecs-service)
#                                                   ├─ rule ...     ──► next service ka target group
#                                                   └─ default      ──► 404 (koi rule match nahi hua)
#
# Target groups ab har service ka module banata hai. Yahan sirf ALB + listener hai.

# ---------- 1. The load balancer ----------
resource "aws_lb" "main" {
  name               = "learning-alb"
  load_balancer_type = "application"                                                 # ALB = Layer 7 (HTTP)
  internal           = false                                                         # internet-facing → needs PUBLIC subnets
  security_groups    = [data.terraform_remote_state.network.outputs.alb_sg_id]       # a string, so wrap it in [ ]
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids # already a list (2 AZs)

  drop_invalid_header_fields = true # security best practice: reject malformed headers

  tags = { Name = "learning-alb" }
}

# ---------- 2. Listener :80, default = 404 ----------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Production: a 443 listener with an ACM certificate, and port 80 redirecting to 443.
  # We have no domain/certificate, so we use plain HTTP.
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"no service matches this path\"}"
      status_code  = "404"
    }
  }
}
