# ================= Test servers for Lesson 2.6 =================

variable "enable_test_instances" {
  description = "Create the two test EC2 instances (they cost money while running)"
  type        = bool
  default     = false
}

# ---------- Find the latest Amazon Linux 2023 image (AMI) ----------
# A "data source" READS something that already exists; it creates nothing.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- IAM role: lets the servers talk to SSM ----------
resource "aws_iam_role" "ssm" {
  name = "learning-ec2-ssm-role"

  # Trust policy: WHO may assume this role → the EC2 service
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Permissions: WHAT the role may do → the AWS-managed SSM policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# The wrapper that attaches the role to an EC2 instance
resource "aws_iam_instance_profile" "ssm" {
  name = "learning-ec2-ssm-profile"
  role = aws_iam_role.ssm.name
}

# ---------- Security group for the test servers ----------
resource "aws_security_group" "test" {
  name        = "test-sg"
  description = "Test servers: ping from inside the VPC only"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "test-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "test_icmp_from_vpc" {
  security_group_id = aws_security_group.test.id
  description       = "Ping from inside the VPC only"
  cidr_ipv4         = aws_vpc.main.cidr_block    # 10.0.0.0/16, NOT the internet
  ip_protocol       = "icmp"
  from_port         = -1                          # -1 = all ICMP types
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "test_all_out" {
  security_group_id = aws_security_group.test.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"                        # needed for SSM, updates and curl
}

# ---------- The two test servers ----------
resource "aws_instance" "public" {
  count                  = var.enable_test_instances ? 1 : 0
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id          # PUBLIC subnet → gets a public IP
  vpc_security_group_ids = [aws_security_group.test.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  metadata_options {
    http_tokens = "required"    # IMDSv2 only (security best practice, explained below)
  }

  tags = { Name = "test-public" }
}

resource "aws_instance" "private" {
  count                  = var.enable_test_instances ? 1 : 0
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_a.id         # PRIVATE subnet → no public IP
  vpc_security_group_ids = [aws_security_group.test.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "test-private" }
}

output "test_public_private_ip" {
  value = var.enable_test_instances ? aws_instance.public[0].private_ip : null
}

output "test_private_private_ip" {
  value = var.enable_test_instances ? aws_instance.private[0].private_ip : null
}