terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

resource "kind_cluster" "default" {
    name = "mi-test-cluster"
    #node_image     = "kindest/node:v1.31.0"
    wait_for_ready = true
    kind_config {
        kind        = "Cluster"
        api_version = "kind.x-k8s.io/v1alpha4"

        node {
            role = "control-plane"
        }

        node {
            role = "worker"
        }

        node {
            role = "worker"
        }
    }
}

resource "kubernetes_deployment_v1" "nginx" {
  depends_on = [kind_cluster.default]
  metadata {
    name = "nginx-deployment"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  depends_on = [kind_cluster.default]
  metadata {
    name = "nginx-service"
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
      node_port   = 30080
    }
    type = "NodePort"
  }
}