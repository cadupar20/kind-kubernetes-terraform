# ============================================================
# Variables de entrada de Terraform
# ============================================================
# Estas variables permiten personalizar la configuración del
# clúster sin modificar el código principal.

# Nombre del clúster Kind
# Se usa en main.tf para identificar el clúster y como parte
# del contexto en kubectl. Por defecto: "local-kind-cluster".
variable "cluster_name" {
  type        = string
  description = "Nombre del clúster Kind. Se usa para identificar el clúster en kubectl."
  default     = "local-kind-cluster"
}

# Ruta del archivo kubeconfig
# Define dónde se guarda el archivo de configuración para
# acceder al clúster con kubectl. Por defecto: ~/.kube/config.
# Si se cambia, usar: kubectl --kubeconfig=<ruta> get nodes
variable "cluster_config_path" {
  type        = string
  description = "Ruta del archivo kubeconfig generado por Kind para acceder al clúster."
  default     = "~/.kube/config"
}