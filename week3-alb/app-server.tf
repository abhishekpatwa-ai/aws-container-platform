# Latest Amazon Linux 2023 image (data source = READ only, creates nothing)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- Demo app server in a PRIVATE subnet ----------
resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  subnet_id              = data.terraform_remote_state.network.outputs.private_subnet_ids[0]      # 🤔 FIRST private subnet (hint: it's a list → [0])
  vpc_security_group_ids = [data.terraform_remote_state.network.outputs.app_sg_id]  # 🤔 which SG allows 8080 from the ALB?

  metadata_options {
    http_tokens = "required"         # IMDSv2 only
  }

  # Runs once at first boot: a tiny web server on 8080 (Python is built into AL2023)
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /srv/www
    echo "<h1>Hello from $(hostname) in a PRIVATE subnet, via the ALB</h1>" > /srv/www/index.html
    systemd-run --unit=web python3 -m http.server 8080 --directory /srv/www
  EOF

  tags = { Name = "learning-app" }
}

# ---------- Register the server into the target group ----------
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.private_ip  # 🤔 target_type is "ip", so which attribute of aws_instance.app?
  port             = 8080
}