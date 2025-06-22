data "aws_eks_cluster_auth" "eks_auth" {
  name = module.eks_cluster.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority)
    token                  = data.aws_eks_cluster_auth.eks_auth.token
  }
}


resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.12.1"
  values           = [file("${path.module}/nginx.yaml")]

  set = [
    {
      name  = "controller.service.internal.enabled"
      value = "true"
    }
  ]


  depends_on = [module.eks_cluster]
}
