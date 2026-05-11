# Cluster3 — Clúster Kind con Terraform, Ingress Controller y aplicación de prueba

Este directorio extiende el enfoque de `cluster2` con una configuración más completa: clúster de **1 control-plane + 2 workers**, instalación automática del **Nginx Ingress Controller**, mapeo de puertos del host, y una aplicación de prueba con Deployment, Service e Ingress gestionados como manifiestos Kubernetes.

## Estructura del Proyecto
```
.
├── cluster3/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ├── ingress.tf
   └──kubernetes/
           └── test-app.yaml
```

## Contenido

| Archivo / Carpeta | Descripción |
|---|---|
| `main.tf` | Clúster Kind con port mappings, label ingress-ready y 3 nodos |
| `versions.tf` | Versiones requeridas de Terraform y providers |
| `variables.tf` | Variables configurables: nombre del clúster y ruta del kubeconfig |
| `outputs.tf` | Outputs: nombre del clúster, kubeconfig path, workers, estado ingress |
| `ingress.tf` | Instalación automática del Nginx Ingress Controller vía `null_resource` |
| `kubernetes/test-app.yaml` | Aplicación de prueba: Deployment + Service + Ingress |
| `.terraform.lock.hcl` | Lock file de versiones de providers |
| `terraform.tfstate` | Estado actual de la infraestructura |

## Topología del clúster

```
local-kind-cluster
├── control-plane  (puerto 80 y 443 mapeados al host, label ingress-ready=true)
├── worker         (nodo 1)
└── worker         (nodo 2)
```

## Configuración detallada

### `main.tf` — Clúster Kind

```hcl
resource "kind_cluster" "default" {
  name            = var.cluster_name        # default: "local-kind-cluster"
  kubeconfig_path = pathexpand(var.cluster_config_path)  # default: ~/.kube/config
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      # Etiqueta necesaria para que el Ingress Controller se despliegue en este nodo
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      # Mapeo de puertos: el host escucha en 80/443 y redirige al contenedor
      extra_port_mappings {
        container_port = 80
        host_port      = 80
        listen_address = "0.0.0.0"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
        listen_address = "0.0.0.0"
      }
    }

    node { role = "worker" }
    node { role = "worker" }
  }
}
```

Diferencias clave respecto a `cluster2`:
- **Port mappings** en el control-plane: los puertos 80 y 443 del host se redirigen al contenedor, permitiendo acceder al Ingress Controller directamente desde `localhost`.
- **Label `ingress-ready=true`** aplicada vía `kubeadm_config_patches`: requerida por el Nginx Ingress Controller para seleccionar el nodo donde desplegarse.
- **2 workers** en lugar de 1, para distribuir las cargas de trabajo.

### `versions.tf` — Providers requeridos

```hcl
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
  required_version = ">= 1.0.0"
}
```

Se agregan dos providers respecto a `cluster2`:
- **`hashicorp/kubernetes` v2.33.0** — permite gestionar recursos Kubernetes desde Terraform.
- **`hashicorp/null` v3.2.4** — usado internamente por `ingress.tf` para ejecutar comandos locales.

### `variables.tf` — Variables configurables

| Variable | Tipo | Default | Descripción |
|---|---|---|---|
| `cluster_name` | string | `local-kind-cluster` | Nombre del clúster Kind |
| `cluster_config_path` | string | `~/.kube/config` | Ruta del archivo kubeconfig |

### `ingress.tf` — Instalación automática del Ingress Controller

```hcl
resource "null_resource" "install_ingress_nginx" {
  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
      kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    EOT
  }
}
```

- Se ejecuta **después** de que el clúster esté listo (`depends_on`).
- Aplica el manifiesto oficial de Nginx Ingress para Kind.
- Espera hasta 90 segundos a que el pod del controller esté en estado `Ready`.

### `outputs.tf` — Valores de salida

Tras el `terraform apply`, se muestran:

| Output | Descripción |
|---|---|
| `cluster_name` | Nombre del clúster creado |
| `kubeconfig_path` | Ruta del kubeconfig generado |
| `control_plane_ip` | Imagen del nodo (referencia a la versión de Kubernetes) |
| `worker_nodes` | Número de nodos worker (2) |
| `ingress_ready` | Indica si el control-plane tiene el label `ingress-ready=true` (1 = sí) |

### `kubernetes/test-app.yaml` — Aplicación de prueba

Contiene tres recursos en un solo archivo:

```yaml
# Deployment: 2 réplicas de hello-app (Google sample app)
# Service: ClusterIP en puerto 80 → 8080
# Ingress: ruta /hello → hello-service:80
```

La aplicación responde con el hostname del pod, lo que permite verificar el balanceo de carga entre réplicas al hacer múltiples requests.

## Requisitos previos

- [Docker Desktop](https://docs.docker.com/get-docker/) en ejecución
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Instalación con Chocolatey (Windows)

```sh
choco install docker-desktop -y
choco install terraform -y
choco install kubernetes-cli -y
```

## Paso a paso

### 1. Inicializar Terraform

```sh
cd cluster3
terraform init
```

Descarga los providers `tehcyx/kind`, `hashicorp/kubernetes` y `hashicorp/null`.

### 2. Revisar el plan

```sh
terraform plan
```

### 3. Crear el clúster e instalar el Ingress Controller

```sh
terraform apply -auto-approve
```

Salida esperada:

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
cluster_name    = "local-kind-cluster"
ingress_ready   = 1
kubeconfig_path = "C:\Users\<usuario>\.kube\config"
worker_nodes    = 2
```

### 4. Verificar el clúster y el Ingress Controller

```sh
# Nodos del clúster
kubectl get nodes

# Pod del Ingress Controller
kubectl get pods -n ingress-nginx
```

```
NAME                                      READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-bd44dc47-hlk29   1/1     Running   0          1m
```

### 5. Desplegar la aplicación de prueba

```sh
kubectl apply -f kubernetes/test-app.yaml
```

Verificar los recursos:

```sh
kubectl get pods
kubectl get services
kubectl get ingress
```

### 6. Probar el acceso

Gracias al mapeo de puertos, la aplicación es accesible directamente desde `localhost`:

```sh
curl http://localhost/hello
```

Respuesta esperada:

```
Hello, world!
Version: 1.0.0
Hostname: hello-app-546c66f4c8-2sjfx
```

Ejecutar el comando varias veces para observar el balanceo de carga entre los 2 pods (el `Hostname` cambia en cada request).

### 7. Verificar logs del Ingress Controller

```sh
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

## Despliegue del Clúster

```bash
cd cluster3
terraform init

Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/null...
- Finding hashicorp/kubernetes versions matching "2.33.0"...
- Finding tehcyx/kind versions matching "0.9.0"...
- Installing hashicorp/null v3.2.4...
- Installed hashicorp/null v3.2.4 (signed by HashiCorp)
- Installing hashicorp/kubernetes v2.33.0...
- Installed hashicorp/kubernetes v2.33.0 (signed by HashiCorp)
- Installing tehcyx/kind v0.11.0...
- Installed tehcyx/kind v0.11.0 (self-signed)
Partner and community providers are signed by their developers.

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.


terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # kind_cluster.default will be created
  + resource "kind_cluster" "default" {
      + client_certificate     = (known after apply)
      + client_key             = (known after apply)
      + cluster_ca_certificate = (known after apply)
      + completed              = (known after apply)
      + endpoint               = (known after apply)
      + id                     = (known after apply)
      + kubeconfig             = (known after apply)
      + kubeconfig_path        = "C:\\Users\\ar_ke\\.kube\\config"
      + name                   = "local-kind-cluster"
      + node_image             = (known after apply)
      + wait_for_ready         = true

      + kind_config {
          + api_version = "kind.x-k8s.io/v1alpha4"
          + kind        = "Cluster"

          + node {
              + kubeadm_config_patches = [
                  + <<-EOT
                        kind: InitConfiguration
                        nodeRegistration:
                          kubeletExtraArgs:
                            node-labels: "ingress-ready=true"
                    EOT,
                ]
              + role                   = "control-plane"

              + extra_port_mappings {
                  + container_port = 80
                  + host_port      = 80
                  + listen_address = "0.0.0.0"
                }
              + extra_port_mappings {
                  + container_port = 443
                  + host_port      = 443
                  + listen_address = "0.0.0.0"
                }
            }
          + node {
              + role = "worker"
            }
          + node {
              + role = "worker"
            }
        }
    }

  # null_resource.install_ingress_nginx will be created
  + resource "null_resource" "install_ingress_nginx" {
      + id = (known after apply)
    }

#Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cluster_name     = "local-kind-cluster"
  + control_plane_ip = (known after apply)
  + ingress_ready    = 1
  + kubeconfig_path  = "C:\\Users\\ar_ke\\.kube\\config"
  + worker_nodes     = 2



terraform apply -auto-approve

#Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

cluster_name = "local-kind-cluster"
ingress_ready = 1
kubeconfig_path = "C:\\Users\\ar_ke\\.kube\\config"
worker_nodes = 2
```



## Personalización

### Cambiar el nombre del clúster

```sh
terraform apply -var="cluster_name=mi-cluster-dev" -auto-approve
```

### Cambiar la ruta del kubeconfig

```sh
terraform apply -var="cluster_config_path=~/.kube/cluster3-config" -auto-approve
```

## Limpieza de Infraestructura

```sh
# Eliminar la aplicación de prueba
kubectl delete -f kubernetes/test-app.yaml

# Destruir el clúster y toda la infraestructura
terraform destroy -auto-approve
```

## Referencias

- [Provider tehcyx/kind — Terraform Registry](https://registry.terraform.io/providers/tehcyx/kind/latest)
- [Nginx Ingress Controller para Kind](https://kind.sigs.k8s.io/docs/user/ingress/)
- [hashicorp/kubernetes provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest)
- [Google hello-app sample](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/tree/main/quickstarts/hello-app)
