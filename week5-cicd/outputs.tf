output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn # har service ka deploy role isi par bharosa karta hai
}
