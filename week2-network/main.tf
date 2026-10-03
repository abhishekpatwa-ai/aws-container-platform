# ---------- The VPC (the "city") ----------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true    # AWS DNS works inside the VPC
  enable_dns_hostnames = true    # resources get DNS names (needed later for ECS, EKS, endpoints)

  tags = { Name = "learning-vpc" }
}

# ---------- Public subnets ----------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id      # ← this subnet lives INSIDE the VPC
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true                 # servers here get a public IP automatically

  tags = { Name = "public-a", Tier = "public" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = { Name = "public-b", Tier = "public" }
}

# ---------- Private subnets ----------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-1a"

  tags = { Name = "private-a", Tier = "private" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "eu-west-1b"

  tags = { Name = "private-b", Tier = "private" }
}


# ---------- Internet Gateway: the door ----------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id               # attach the door to our VPC

  tags = { Name = "learning-igw" }
}

# ---------- Public route table: the road signs ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                         # "everything else..."
    gateway_id = aws_internet_gateway.main.id        # "...goes out through the IGW"
  }
  # the local route (10.0.0.0/16 → local) is added automatically. Don't write it.

  tags = { Name = "public-rt" }
}

# ---------- Associations: link the public subnets to the public route table ----------
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ---------- Private route tables: one per AZ (NAT routes come in Lesson 2.4) ----------
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "private-a-rt" }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "private-b-rt" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}


# ---------- Elastic IP: the NAT Gateway's fixed public address ----------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = { Name = "learning-nat-eip" }
}

# ---------- NAT Gateway: lives in a PUBLIC subnet ----------
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id           # attach the Elastic IP
  subnet_id     = aws_subnet.public_a.id      # PUBLIC subnet, so it can use the IGW

  tags = { Name = "learning-nat" }

  depends_on = [aws_internet_gateway.main]    # the IGW must exist first
}

# ---------- Routes: private subnets → NAT ----------
resource "aws_route" "private_a_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

resource "aws_route" "private_b_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id    # both use the same NAT (single-NAT design)
}

# ================= Security groups =================

# ---------- ALB security group: the public entry point ----------
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Load balancer: HTTPS/HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "alb-sg" }
}

# ---------- App security group: only reachable through the ALB ----------
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "App servers: traffic only from the ALB"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "app-sg" }
}

# ---------- ALB rules ----------
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere (we will redirect it to HTTPS later)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "ALB may only talk to the app on 8080"
  referenced_security_group_id = aws_security_group.app.id     # ← SG referencing SG
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

# ---------- App rules ----------
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "8080 only from the ALB security group"
  referenced_security_group_id = aws_security_group.alb.id     # ← not an IP!
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "app_all_out" {
  security_group_id = aws_security_group.app.id
  description       = "App can reach the internet via NAT (updates, APIs)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"                                       # -1 = all protocols, all ports
}

# ---------- Lock down the default security group (CIS best practice) ----------
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  # No ingress or egress blocks = Terraform REMOVES all rules from the default SG
  tags = { Name = "default-sg-locked" }
}