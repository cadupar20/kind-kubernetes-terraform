# ============================================================
# Configuración de Terraform y Providers
# ============================================================
terraform {
  required_providers {
    # Provider tehcyx/kind: permite gestionar clústeres Kubernetes
    # locales con Kind (Kubernetes IN Docker) desde Terraform.
    # Versión 0.11.0 (actualizada a la última disponible).
    kind = {
      source  = "tehcyx/kind"
      version = "0.11.0"
    }
    # Provider hashicorp/kubernetes: permite desplegar y gestionar
    # recursos de Kubernetes (Deployments, Services, etc.)
    # directamente desde Terraform, una vez que el clúster existe.
    # Versión 2.33.0.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
}

# ============================================================
# Provider Kind
# ============================================================
# Configura el provider de Kind para crear clústeres locales
# usando contenedores Docker como nodos. No requiere
# configuración adicional.
provider "kind" {}

# ============================================================
# Provider Kubernetes
# ============================================================
# Configura el provider de Kubernetes para interactuar con el
# clúster recién creado. Usa el kubeconfig por defecto
# (~/.kube/config) generado por Kind tras la creación.
# Puerto utilizado: 6443 (API Server de Kubernetes, por defecto).
provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

# ============================================================
# Recurso: Clúster Kind
# ============================================================
# Crea un clúster Kubernetes local con Kind.
# Detalles del clúster:
#   - Nombre: "mi-test-cluster"
#   - Topología: 1 nodo control-plane + 2 nodos worker
#   - wait_for_ready: true → Terraform espera a que todos los
#     nodos estén en estado "Ready" antes de continuar
#   - node_image: comentada → usa la imagen por defecto de la
#     versión instalada de Kind
# Puerto utilizado: el API Server de Kubernetes escucha en el
# puerto 6443 dentro de la red de Docker.
resource "kind_cluster" "default" {
    name = "mi-test-cluster"
    #node_image     = "kindest/node:v1.31.0"
    wait_for_ready = true
    kind_config {
        kind        = "Cluster"
        api_version = "kind.x-k8s.io/v1alpha4"

        # Nodo control-plane: gestiona el clúster, programa pods,
        # y ejecuta los componentes del plano de control.
        node {
            role = "control-plane"
        }

        # Nodo worker 1: ejecuta las cargas de trabajo (pods de
        # aplicación). Pueden escalarse agregando más nodos.
        node {
            role = "worker"
        }

        # Nodo worker 2: segundo nodo worker para distribución
        # de cargas y alta disponibilidad de las aplicaciones.
        node {
            role = "worker"
        }
    }
}

# ============================================================
# Recurso: Deployment de Nginx
# ============================================================
# Despliega la aplicación nginx en el clúster Kind creado arriba.
# depends_on: asegura que el clúster exista antes de desplegar.
# Detalles del Deployment:
#   - Nombre: "nginx-deployment"
#   - Réplicas: 2 (dos pods para balanceo de carga)
#   - Imagen: nginx:latest (servidor web oficial de nginx)
#   - Puerto container: 80 (puerto HTTP por defecto de nginx)
resource "kubernetes_deployment_v1" "nginx" {
  depends_on = [kind_cluster.default]
  metadata {
    name = "nginx-deployment"
  }
  spec {
    # Número de réplicas (pods) que ejecutarán nginx
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
        # Configuración del contenedor nginx
        container {
          name  = "nginx"
          image = "nginx:latest"
          # Puerto 80: puerto HTTP estándar donde nginx sirve
          # contenido web.
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# ============================================================
# Recurso: Service de Nginx (NodePort)
# ============================================================
# Expone el Deployment de nginx al exterior del clúster mediante
# un Service de tipo NodePort.
# depends_on: asegura que el clúster exista antes de crear el Service.
# Detalles del Service:
#   - Nombre: "nginx-service"
#   - Tipo: NodePort (accesible desde fuera del clúster)
#   - Puerto interno (port): 80 → puerto del Service dentro del clúster
#   - Target port: 80 → puerto del contenedor nginx al que redirige
#   - NodePort: 30080 → puerto en la IP del host para acceso externo
#   - Selector: app = nginx → enruta tráfico a los pods con esa etiqueta
# Acceso desde el navegador: http://localhost:30080
resource "kubernetes_service_v1" "nginx" {
  depends_on = [kind_cluster.default]
  metadata {
    name = "nginx-service"
  }
  spec {
    # Selector que vincula este Service con los pods del Deployment
    selector = {
      app = "nginx"
    }
    port {
      # port: puerto interno del Service (dentro del clúster)
      port        = 80
      # target_port: puerto del contenedor al que se redirige
      target_port = 80
      # node_port: puerto externo en el host para acceso desde afuera
      node_port   = 30080
    }
    # Tipo NodePort: expone el Service en un puerto estático en
    # todos los nodos del clúster, permitiendo acceso externo.
    type = "NodePort"
  }
}