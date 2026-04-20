resource "helm_release" "this" {
  name             = var.release_name
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = var.values
}
