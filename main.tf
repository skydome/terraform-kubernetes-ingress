resource "kubernetes_config_map" "nginx_configuration" {
  count = length(var.namespaces)
  metadata {
    name      = "nginx-configuration"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
}

resource "kubernetes_config_map" "tcp_services" {
  count = length(var.namespaces)
  metadata {
    name      = "tcp-services"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
}

resource "kubernetes_config_map" "udp_services" {
  count = length(var.namespaces)
  metadata {
    name      = "udp-services"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
}

resource "kubernetes_service_account" "nginx_ingress_serviceaccount" {
  count = length(var.namespaces)
  metadata {
    name      = "nginx-ingress-serviceaccount"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
}

resource "kubernetes_cluster_role" "nginx_ingress_clusterrole" {
  metadata {
    name   = "nginx-ingress-clusterrole"
    labels = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets"]
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["nodes"]
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services"]
  }
  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
  }
  rule {
    verbs      = ["update"]
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status"]
  }
}

resource "kubernetes_role" "nginx_ingress_role" {
  count = length(var.namespaces)
  metadata {
    name      = "nginx-ingress-role"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["configmaps", "pods", "secrets", "namespaces"]
  }
  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["ingress-controller-leader-nginx"]
  }
  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["configmaps"]
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["endpoints"]
  }
}

resource "kubernetes_role_binding" "nginx_ingress_role_nisa_binding" {
  count = length(var.namespaces)
  metadata {
    name      = "nginx-ingress-role-nisa-binding"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "nginx-ingress-serviceaccount"
    namespace = var.namespaces[count.index]
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "nginx-ingress-role"
  }
}

resource "kubernetes_cluster_role_binding" "nginx_ingress_clusterrole_nisa_binding" {
  count = length(var.namespaces)
  metadata {
    name   = "${var.namespaces[count.index]}-nginx-ingress-clusterrole-nisa-binding"
    labels = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "nginx-ingress-serviceaccount"
    namespace = var.namespaces[count.index]
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "nginx-ingress-clusterrole"
  }
}

resource "kubernetes_deployment" "nginx_ingress_controller" {
  count = length(var.namespaces)
  metadata {
    name      = "nginx-ingress-controller"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
  spec {
    replicas = var.replicacount
    selector {
      match_labels = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
    }
    template {
      metadata {
        labels      = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
        annotations = { "prometheus.io/port" = "10254", "prometheus.io/scrape" = "true" }
      }
      spec {
        automount_service_account_token = true
        container {
          name  = "nginx-ingress-controller"
          image = "quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.25.1"
          args  = ["/nginx-ingress-controller", "--configmap=$(POD_NAMESPACE)/nginx-configuration", "--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services", "--udp-services-configmap=$(POD_NAMESPACE)/udp-services", "--publish-service=$(POD_NAMESPACE)/ingress-nginx", "--annotations-prefix=nginx.ingress.kubernetes.io", "--watch-namespace=$(POD_NAMESPACE)"]
          port {
            name           = "http"
            container_port = 80
          }
          port {
            name           = "https"
            container_port = 443
          }
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "10254"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 10
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "10254"
              scheme = "HTTP"
            }
            timeout_seconds   = 10
            period_seconds    = 10
            success_threshold = 1
            failure_threshold = 3
          }
          security_context {
            capabilities {
              add  = ["NET_BIND_SERVICE"]
              drop = ["ALL"]
            }
            run_as_user                = 33
            allow_privilege_escalation = true
          }
        }
        service_account_name = "nginx-ingress-serviceaccount"
      }
    }
  }
}

resource "kubernetes_service" "ingress_nginx" {
  count = length(var.namespaces)
  metadata {
    name      = "ingress-nginx"
    namespace = var.namespaces[count.index]
    labels    = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
  }
  spec {
    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
    port {
      name        = "https"
      port        = 443
      target_port = "https"
    }
    selector                = { "app.kubernetes.io/name" = "ingress-nginx", "app.kubernetes.io/part-of" = "ingress-nginx" }
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}

