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
    # recursos de Kubernetes (Deployments, Services, Ingress, etc.)
    # directamente desde Terraform, una vez que el clúster existe.
    # Versión 2.33.0.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }

  # Versión mínima de Terraform requerida: 1.0.0 o superior.
  required_version = ">= 1.0.0"
}