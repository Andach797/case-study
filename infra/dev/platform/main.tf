locals {
  b = data.terraform_remote_state.bootstrap.outputs

  argocd_chart_version         = "8.1.2"
  argocd_image_updater_version = "0.12.3"

  sm_csi_chart_version    = "1.5.2" # kubernetes-sigs/secrets-store-csi-driver
  sm_aws_provider_version = "0.3.9" # aws/secrets-store-csi-driver-provider-aws
}

module "sm_csi_irsa" {
  source      = "../../modules/irsa_sa"
  name_prefix = "${var.project_tag}-${var.environment}-sm-csi"
  namespace   = "kube-system"

  oidc_arn = local.b.oidc_arn
  oidc_url = replace(local.b.oidc_url, "https://", "")

  secret_arns = [local.b.web_app_secret_arn]
  tags        = var.tags
}

resource "helm_release" "secrets_store_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = local.sm_csi_chart_version
  namespace  = "kube-system"

  values = [yamlencode({
    syncSecret           = { enabled = true }
    enableSecretRotation = true
    serviceAccount = {
      create = false # we’ll reuse IRSA below
      name   = module.sm_csi_irsa.service_account_name
      annotations = {
        "eks.amazonaws.com/role-arn" = module.sm_csi_irsa.role_arn
      }
    }
  })]
}

resource "helm_release" "secrets_store_aws_provider" {
  name       = "secrets-store-csi-driver-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = local.sm_aws_provider_version
  namespace  = "kube-system"

  values = [yamlencode({
    serviceAccount = {
      create = false
      name   = module.sm_csi_irsa.service_account_name
      annotations = {
        "eks.amazonaws.com/role-arn" = module.sm_csi_irsa.role_arn
      }
    }
  })]

  depends_on = [helm_release.secrets_store_csi_driver]
}

module "web_app_irsa" {
  source      = "../../modules/irsa_sa"
  name_prefix = "${var.project_tag}-${var.environment}-web-app"
  namespace   = "default"

  bucket_arn  = "arn:aws:s3:::${local.b.csv_bucket}"
  secret_arns = [local.b.web_app_secret_arn]

  oidc_arn = local.b.oidc_arn
  oidc_url = replace(local.b.oidc_url, "https://", "")
  tags     = var.tags
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = local.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [yamlencode({
    server = {
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
        }
      }
      extraArgs = ["--insecure"]
    }
  })]

  atomic          = true
  wait            = true
  timeout         = 900
  cleanup_on_fail = true
}
# Image updater

# module "argocd_image_updater_irsa" {
#   source      = "../../modules/irsa_sa"
#   name_prefix = "${var.project_tag}-${var.environment}-image-updater"
#   namespace   = helm_release.argocd.namespace

#   ecr_repo_arn = local.b.repository_arn
#   oidc_arn     = local.b.oidc_arn
#   oidc_url     = replace(local.b.oidc_url, "https://", "")
#   tags         = var.tags
# }
# data "kubernetes_secret_v1" "argocd_admin_pwd" {
#   depends_on = [helm_release.argocd]

#   metadata {
#     name      = "argocd-initial-admin-secret"
#     namespace = helm_release.argocd.namespace
#   }
# }

# resource "kubernetes_secret_v1" "argocd_image_updater_token" {
#   metadata {
#     name      = "argocd-image-updater-secret"
#     namespace = helm_release.argocd.namespace
#   }
#   type = "Opaque"
# }

# resource "null_resource" "generate_argocd_token" {
#   depends_on = [
#     kubernetes_secret_v1.argocd_image_updater_token,
#     data.kubernetes_secret_v1.argocd_admin_pwd
#   ]

#   triggers = {
#     admin_pw_hash = data.kubernetes_secret_v1.argocd_admin_pwd.data["password"]
#   }

#   provisioner "local-exec" {
#     interpreter = ["/bin/sh", "-c"]
#     command     = "${path.module}/scripts/gen-argocd-token.sh ${data.kubernetes_secret_v1.argocd_admin_pwd.data["password"]}"
#   }
# }


# # resource "kubernetes_secret_v1" "image_updater_git" {
#   metadata {
#     name      = "git-creds"
#     namespace = helm_release.argocd.namespace
#   }
#   type = "Opaque"
#   data = {
#     token = base64encode(var.github_pat)
#   }
# }

# resource "helm_release" "argocd_image_updater" {
#   name       = "argocd-image-updater"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argocd-image-updater"
#   version    = local.argocd_image_updater_version
#   namespace  = helm_release.argocd.namespace

#  values = [yamlencode({
#     serviceAccount = {
#       create = false
#       name   = module.argocd_image_updater_irsa.service_account_name
#     }
#     extraEnv = [
#       { name = "AWS_REGION", value = var.aws_region },
#       { name = "ARGOCD_TOKEN",
#         valueFrom = {
#           secretKeyRef = {
#             name = kubernetes_secret_v1.argocd_image_updater_token.metadata[0].name
#             key  = "argocd.token"
#           }
#         }
#       }
#     ]
#     config = {
#       argocd = {
#         serverAddress = "argocd-server.${helm_release.argocd.namespace}.svc.cluster.local:443"
#         insecure      = true
#       }
#       git = {
#         writeBack = {
#           branch      = "main"
#           credentials = { username = "oauth2", password = "git-creds:token" }
#         }
#       }
#       registries = {
#         "aws-ecr" = {
#           name      = "aws-ecr"
#           type      = "aws"
#           awsRegion = "eu-central-1"
#           prefix    = local.b.ecr_repo_url
#         }
#       }
#     }
#   })]

#   depends_on = [
#     null_resource.generate_argocd_token,
#     kubernetes_secret_v1.image_updater_git
#   ]
# }
