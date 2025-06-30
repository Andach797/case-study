locals {
  b = data.terraform_remote_state.bootstrap.outputs
}

module "web_app_irsa" {
  source      = "../../modules/irsa_sa"
  name_prefix = "${var.project_tag}-${var.environment}-web-app"
  namespace   = "default"

  bucket_arn = "arn:aws:s3:::${local.b.csv_bucket}"
  oidc_arn   = local.b.oidc_arn
  oidc_url   = replace(local.b.oidc_url, "https://", "")

  tags = var.tags
}

resource "helm_release" "web_nginx" {
  name      = "web-nginx"
  chart     = "${path.module}/../../../charts/web-nginx"
  namespace = "default"
  version   = "0.1.0"

  values = [yamlencode({
    image = {
      repository = local.b.ecr_repo_url
      tag        = var.image_tag
    }
    secretArn = local.b.web_app_secret_arn
    efs = {
      fileSystemId  = local.b.efs_fs_id
      accessPointId = local.b.efs_ap_id
    }
  })]
}
