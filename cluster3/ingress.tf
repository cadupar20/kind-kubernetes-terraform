# ============================================================
# Recurso: Instalación del Nginx Ingress Controller
# ============================================================
# Utiliza un null_resource con un provisioner local-exec para
# instalar el Nginx Ingress Controller después de crear el clúster.
# depends_on: asegura que el clúster Kind exista antes de ejecutar.
#
# Pasos que realiza:
#   1. Aplica el manifiesto oficial de Nginx Ingress para Kind
#      desde el repositorio de kubernetes/ingress-nginx.
#   2. Espera hasta 90 segundos a que el pod del controller esté
#      en estado "Ready" en el namespace ingress-nginx.
#
# Puertos utilizados por el Ingress Controller:
#   - Puerto 80 (HTTP): recibe tráfico HTTP entrante
#   - Puerto 443 (HTTPS): recibe tráfico HTTPS entrante
#
# El Ingress Controller se despliega en el nodo control-plane
# gracias al label "ingress-ready=true" configurado en main.tf.
resource "null_resource" "install_ingress_nginx" {
  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command = <<-EOT
      # Aplica el manifiesto oficial de Nginx Ingress para Kind
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

      # Espera hasta 90 segundos a que el controller esté listo
      kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    EOT
  }
}