# variables.tf
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway (costs money while it exists)"
  type        = bool
  default     = false
}