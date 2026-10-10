# ================= Lesson 4.2: ECS IAM roles =================

# ---------- Trust policy: WHO may wear these roles → ECS tasks ----------
# दोनों roles का trust एक ही है, इसलिए एक बार लिखकर दोनों में use करेंगे
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"] # 🤔 Blank 1: ECS *tasks* की service
    }
  }
}

# ---------- 1. Execution role: the hotel staff (ECR pull + CloudWatch logs) ----------
resource "aws_iam_role" "execution" {
  name               = "learning-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------- 2. Task role: the guest's key card (the app's own AWS access) ----------
resource "aws_iam_role" "task" {
  name               = "learning-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json # 🤔 Blank 2: वही trust policy
  # No permissions yet: our demo app doesn't call AWS. Least privilege.
}