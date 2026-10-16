# ================= Service: uconia-api =================
# Nayi service jodni ho? Ye file copy karo, naam/path/priority badlo. Bas.

module "uconia_api" {
  source = "../modules/ecs-service"

  # --- Service ki apni values ---
  name              = "uconia-api"
  github_repo       = "abhishekpatwa-ai/uconia-api" # sirf is repo ki main branch deploy kar sakti hai
  path_pattern      = "/api/*"
  listener_priority = 100

  # --- Platform values (sab services ke liye same) ---
  cluster_name       = local.platform.cluster_name
  vpc_id             = local.platform.vpc_id
  private_subnet_ids = local.platform.private_subnet_ids
  app_sg_id          = local.platform.app_sg_id
  listener_arn       = local.platform.listener_arn
  oidc_provider_arn  = local.platform.oidc_provider_arn
}
