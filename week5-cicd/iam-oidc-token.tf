# ================= Lesson 5.1: GitHub Actions → AWS without access keys (OIDC) =================
#
# Platform level: account mein EK hi baar. AWS ko batata hai "GitHub ke tokens par bharosa karo".
#
# Har service ka DEPLOY ROLE yahan nahi, modules/ecs-service/iam.tf mein banta hai:
#   uconia-api-github-deploy → sirf abhishekpatwa-ai/uconia-api ki main branch le sakti hai,
#   aur sirf uconia-api ko deploy kar sakti hai.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com" # GitHub ka token issuer
  client_id_list = ["sts.amazonaws.com"]                         # token AWS STS ke liye bana ho (aud)
}

# Resource ka naam "this" se "github" kiya. "moved" Terraform ko batata hai ki ye wahi resource hai,
# warna wo purana delete karke naya banata (aur ek account mein ek hi GitHub provider ho sakta hai).
moved {
  from = aws_iam_openid_connect_provider.this
  to   = aws_iam_openid_connect_provider.github
}
