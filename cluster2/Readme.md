# Cluster2 — Clúster Kind con Terraform (1 control-plane + 1 worker)

Este directorio contiene la configuración de **Terraform** para aprovisionar un clúster Kubernetes local usando [kind](https://kind.sigs.k8s.io/) a través del provider [`tehcyx/kind`](https://registry.terraform.io/providers/tehcyx/kind/latest).

Es el punto de entrada para gestionar infraestructura local como código (IaC), reemplazando los comandos manuales de `kind create cluster` por un flujo declarativo y reproducible con Terraform.

## Contenido

| Archivo | Descripción |
|---|---|
| `main.tf` | Definición del provider y del recurso del clúster Kind + aplicación nginx |
| `kubernetes/nginx-app.yaml` | Manifiesto YAML alternativo de nginx (Deployment + Service NodePort) |
| `.terraform.lock.hcl` | Lock file de versiones de providers (generado automáticamente) |
| `mi-test-cluster-config` | Kubeconfig generado tras el despliegue del clúster |
| `terraform.tfstate` | Estado actual de la infraestructura gestionada por Terraform |
| `terraform.tfstate.backup` | Backup del estado anterior |

## Recursos desplegados

- **Clúster Kind:** `mi-test-cluster` con 1 control-plane y 2 workers
- **Nginx Deployment:** 2 réplicas de `nginx:latest`
- **Nginx Service:** Tipo NodePort en el puerto `30080` del host

## Topología del clúster

```
mi-test-cluster
├── control-plane  (1 nodo)
├── worker         (nodo 1)
└── worker         (nodo 2)
```

## Configuración detallada (`main.tf`)

```hcl
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
  name           = "mi-test-cluster"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }
    node { role = "worker" }
    node { role = "worker" }
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
```

Puntos clave de la configuración:

- **Provider `tehcyx/kind` v0.11.0** — provider no oficial pero ampliamente usado para gestionar clústeres Kind desde Terraform.
- **Provider `hashicorp/kubernetes` v2.33.0** — permite desplegar recursos de Kubernetes (Deployment, Service) directamente desde Terraform.
- **`wait_for_ready = true`** — Terraform espera a que todos los nodos estén en estado `Ready` antes de considerar el recurso como creado exitosamente.
- **Nombre del clúster:** `mi-test-cluster` — el kubeconfig se guarda en la ruta por defecto (`~/.kube/config`) y también en el archivo `mi-test-cluster-config` del directorio.
- **Imagen del nodo:** comentada (`#node_image = "kindest/node:v1.31.0"`), por lo que usa la imagen por defecto de la versión del provider instalado. Se puede descomentar para fijar una versión específica de Kubernetes.
- **Nginx Deployment:** Se despliegan automáticamente 2 réplicas de `nginx:latest` al crear el clúster.
- **Nginx Service:** Se expone en el puerto `30080` del host como NodePort.

## Requisitos previos

- [Docker Desktop](https://docs.docker.com/get-docker/) en ejecución
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (para interactuar con el clúster)

### Instalación con Chocolatey (Windows)

```sh
choco install docker-desktop -y
choco install terraform -y
choco install kubernetes-cli -y
```

### Verificar instalaciones

```sh
docker --version
terraform version
kubectl version --client
```

## Paso a paso

### 1. Inicializar Terraform

Descarga el provider `tehcyx/kind` y genera el lock file:

```sh
cd cluster2
terraform init
```

Salida esperada:

```
Initializing provider plugins...
- Finding hashicorp/kubernetes versions matching "2.33.0"...
- Finding tehcyx/kind versions matching "0.11.0"...
- Installing hashicorp/kubernetes v2.33.0...
- Installing tehcyx/kind v0.11.0...
- Installed tehcyx/kind v0.11.0 (self-signed, key ID F471C773A530ED1B)
- Installed hashicorp/kubernetes v2.33.0 (signed by HashiCorp)

Terraform has been successfully initialized!
```

### 2. Revisar el plan de ejecución

```sh
terraform plan
```

Muestra los recursos que se van a crear sin aplicar cambios.

### 3. Crear el clúster

```sh
terraform apply -auto-approve
```

Salida esperada:

```
kind_cluster.default: Creating...
kind_cluster.default: Still creating... [10s elapsed]
kind_cluster.default: Creation complete after ~30s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

### 4. Verificar el clúster

```sh
kubectl get nodes
```

```
NAME                            STATUS   ROLES           AGE   VERSION
mi-test-cluster-control-plane   Ready    control-plane   1m    v1.33.1
mi-test-cluster-worker          Ready    <none>          1m    v1.33.1
mi-test-cluster-worker          Ready    <none>          1m    v1.33.1
```

### 5. Verificar la aplicación nginx

```sh
kubectl get pods
```

```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-xxxxxxxxx-xxxxx    1/1     Running   0          30s
nginx-deployment-xxxxxxxxx-xxxxx    1/1     Running   0          30s
```

Para acceder a nginx desde tu navegador, abre `http://localhost:30080`.

### 6. Usar un kubeconfig alternativo (opcional)

Si no quieres sobreescribir tu `~/.kube/config` por defecto, puedes apuntar kubectl al archivo generado:

```sh
kubectl --kubeconfig=mi-test-cluster-config get nodes
```

## Despliegue manual sin Terraform (opcional)

Si prefieres desplegar nginx con kubectl en lugar de que Terraform lo gestione:

```sh
kubectl apply -f kubernetes/nginx-app.yaml
```

Esto crea el mismo Deployment y Service definidos en `main.tf`.

## Personalización

### Fijar versión de Kubernetes

Descomenta la línea `node_image` en `main.tf` para usar una versión específica:

```hcl
node_image = "kindest/node:v1.31.0"
```

Las imágenes disponibles se pueden consultar en [kind releases](https://github.com/kubernetes-sigs/kind/releases).

### Agregar más workers

Añade bloques `node` adicionales en `kind_config`:

```hcl
node {
  role = "worker"
}
node {
  role = "worker"
}
```

## Eliminar el clúster

```sh
terraform destroy -auto-approve
```

Esto elimina el clúster y limpia el estado de Terraform.

## Referencias

- [Provider tehcyx/kind — Terraform Registry](https://registry.terraform.io/providers/tehcyx/kind/latest)
- [kind — Configuración de clústeres](https://kind.sigs.k8s.io/docs/user/configuration/)
- [Terraform — Getting Started](https://developer.hashicorp.com/terraform/tutorials)
