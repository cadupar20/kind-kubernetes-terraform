# ============================================================
# Outputs de Terraform
# ============================================================
# Estos valores se muestran al finalizar "terraform apply".
# Proporcionan información útil del clúster creado.

# Nombre del clúster Kind que se creó
output "cluster_name" {
  description = "Nombre del cluster Kind"
  value       = kind_cluster.default.name
}

# Ruta del archivo kubeconfig generado para acceder al clúster
output "kubeconfig_path" {
  description = "Ruta del archivo kubeconfig"
  value       = kind_cluster.default.kubeconfig_path
}

# Imagen del nodo (versión de Kubernetes) utilizada en el clúster
output "control_plane_ip" {
  description = "IP del nodo control-plane"
  value       = kind_cluster.default.node_image
}

# Número de nodos worker calculado dinámicamente a partir de
# la configuración del clúster. Filtra los nodos con role=worker.
output "worker_nodes" {
  description = "Número de nodos worker"
  value       = length([for node in kind_cluster.default.kind_config[0].node : node if node.role == "worker"])
}

# Indica si el control-plane tiene el label "ingress-ready=true"
# necesario para el Nginx Ingress Controller.
# Retorna 1 si está configurado, 0 si no.
output "ingress_ready" {
  description = "Estado de Ingress Controller (1 = configurado, 0 = no configurado)"
  value       = length([for node in kind_cluster.default.kind_config[0].node : node if node.role == "control-plane" && can(regex("ingress-ready=true", node.kubeadm_config_patches[0]))])
}