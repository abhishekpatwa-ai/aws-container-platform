# AWS Container Platform

Hands-on project: a production-style platform on AWS, built with Terraform. Feature teams ship services on it through a **golden path**: one Terraform module plus one reusable pipeline.

## How it fits together

```
                    Internet
                       │
                ALB (week3-alb, shared)
                listener :80, default 404
                 ├─ /api/*  ─► uconia-api target group
                 └─ ...     ─► next service
                       │
   ECS cluster (week4-ecs, shared) ─ Fargate tasks in private subnets (week2-network)

   Service repo push ─► .github/workflows/ecs-deploy.yml (golden pipeline)
                        OIDC (week5-cicd) → build → push to ECR → scan gate → deploy
```

## Structure

| Folder | What | Owner |
|---|---|---|
| `bootstrap/` | S3 bucket for Terraform remote state (versioning, encryption, locking, prevent_destroy) | Platform |
| `week1-first-bucket/` | Production-style S3 bucket (lesson) | Platform |
| `week2-network/` | VPC, 2 AZs, public/private subnets, IGW, NAT, security groups | Platform |
| `week3-alb/` | Shared ALB + HTTP listener (default 404) | Platform |
| `week4-ecs/` | Shared ECS cluster (Container Insights on) | Platform |
| `week5-cicd/` | GitHub OIDC provider (no access keys anywhere) | Platform |
| `modules/ecs-service/` | **Golden path module**: ECR, task definition, ECS service, target group, ALB rule, autoscaling, execution/task roles, GitHub deploy role | Platform |
| `services/` | One file per service, calling the module | Platform + service teams |
| `.github/workflows/ecs-deploy.yml` | **Golden pipeline** (reusable workflow) | Platform |

## Add a new service

1. Create the service repo with a Dockerfile, a `/health` endpoint, and a 5-line `.github/workflows/deploy.yml` that calls the golden pipeline (see [uconia-api](https://github.com/abhishekpatwa-ai/uconia-api)).
2. Copy `services/uconia-api.tf`, change `name`, `github_repo`, `path_pattern` and `listener_priority`.
3. `terraform apply` in `services/`, then push to the service repo's `main` branch.

## Apply order

Create: `bootstrap` → `week2-network` → `week3-alb` → `week4-ecs` → `week5-cicd` → `services`
Destroy: the reverse (`services` first), because later stacks read earlier stacks' outputs.

## Ownership

Terraform owns the infrastructure. The pipeline owns the image version: the ECS service ignores `task_definition` changes, so `terraform apply` never rolls back a deployment.
