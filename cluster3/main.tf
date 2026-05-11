# ============================================================
# Provider Kind
# ============================================================
# Configura el provider de Kind para crear clústeres Kubernetes
# locales usando contenedores Docker como nodos.
# No requiere configuración adicional.
provider "kind" {
}

# ============================================================
# Provider Kubernetes
# ============================================================
# Configura el provider de Kubernetes para desplegar y gestionar
# recursos (Deployments, Services, etc.) en el clúster Kind.
# Usa la ruta del kubeconfig definida en la variable
# cluster_config_path (por defecto: ~/.kube/config).
# Puerto utilizado: 6443 (API Server de Kubernetes).
provider "kubernetes" {
  config_path = pathexpand(var.cluster_config_path)
}

# ============================================================
# Recurso: Clúster Kind
# ============================================================
# Crea un clúster Kubernetes local con Kind.
# Detalles del clúster:
#   - Nombre: variable "cluster_name" (por defecto: "local-kind-cluster")
#   - Topología: 1 nodo control-plane + 2 nodos worker
#   - wait_for_ready: true → Terraform espera a que todos los
#     nodos estén en estado "Ready" antes de continuar
#   - kubeconfig_path: ruta donde se guarda el kubeconfig
#
# Puertos utilizados:
#   - Puerto 80 (HTTP) → mapeado del host al contenedor
#   - Puerto 443 (HTTPS) → mapeado del host al contenedor
#   - Puerto 6443 → API Server de Kubernetes (interno)
#
# El control-plane tiene el label "ingress-ready=true" necesario
# para que el Nginx Ingress Controller se despliegue en este nodo.
resource "kind_cluster" "default" {
  name            = var.cluster_name
  kubeconfig_path = pathexpand(var.cluster_config_path)
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Nodo control-plane: gestiona el clúster, programa pods,
    # y ejecuta los componentes del plano de control.
    # Incluye el label ingress-ready=true y mapeo de puertos
    # 80/443 para acceso HTTP/HTTPS desde el host.
    node {
      role = "control-plane"

      # kubeadm_config_patches: etiqueta el nodo para que el
      # Ingress Controller pueda seleccionarlo y desplegarse.
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      # Mapeo del puerto 80 (HTTP) del host al contenedor.
      # Escucha en 0.0.0.0 para aceptar conexiones desde
      # cualquier interfaz de red.
      extra_port_mappings {
        container_port = 80
        host_port      = 80
        listen_address  = "0.0.0.0"
      }
      # Mapeo del puerto 443 (HTTPS) del host al contenedor.
      extra_port_mappings {
        container_port = 443
        host_port      = 443
        listen_address  = "0.0.0.0"
      }
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