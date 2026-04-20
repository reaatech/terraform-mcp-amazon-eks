resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = var.iam_role_arn
    }
  }

  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace

    labels = {
      app = var.deployment_name
    }
  }

  spec {
    replicas = var.warm_pool_size

    selector {
      match_labels = {
        app = var.deployment_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.deployment_name
        }
      }

      spec {
        service_account_name = kubernetes_service_account.this.metadata[0].name

        container {
          name  = "mcp-server"
          image = var.image

          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "env" {
            for_each = var.kubernetes_secret_env_vars
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  name = env.value.secret_name
                  key  = env.value.secret_key
                }
              }
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }
        }

        node_selector = var.node_selector

        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = try(toleration.value.value, null)
            effect   = toleration.value.effect
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_account.this]
}

resource "kubernetes_service" "this" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace

    labels = {
      app = var.deployment_name
    }
  }

  spec {
    selector = {
      app = var.deployment_name
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = var.service_type
  }

  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "${var.deployment_name}-hpa"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = var.deployment_name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.target_cpu_utilization
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.target_memory_utilization
        }
      }
    }
  }
}

resource "kubernetes_manifest" "trigger_authentication" {
  count = var.enable_keda_scaling ? 1 : 0

  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "TriggerAuthentication"
    metadata = {
      name      = "${var.deployment_name}-trigger-auth"
      namespace = var.namespace
    }
    spec = {
      podIdentity = {
        provider = "aws"
      }
    }
  }
}

resource "kubernetes_manifest" "scaled_object" {
  count = var.enable_keda_scaling ? 1 : 0

  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = "${var.deployment_name}-scaler"
      namespace = var.namespace
      labels = {
        app = var.deployment_name
      }
    }
    spec = {
      scaleTargetRef = {
        name = var.deployment_name
      }
      minReplicaCount = var.min_replicas
      maxReplicaCount = var.max_replicas
      cooldownPeriod  = var.scale_down_delay
      triggers = [
        {
          type = "aws-sqs-queue"
          authenticationRef = {
            name = "${var.deployment_name}-trigger-auth"
          }
          metadata = {
            queueURL              = var.sqs_queue_url
            queueLength           = tostring(var.scale_up_threshold)
            activationQueueLength = tostring(var.activation_queue_length)
            awsRegion             = var.region
            scaleOnInFlight       = tostring(var.scale_on_in_flight)
            scaleOnDelayed        = tostring(var.scale_on_delayed)
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.trigger_authentication]
}
