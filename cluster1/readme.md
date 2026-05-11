# Cluster1 — Clúster Kubernetes local con Kind (manifiestos YAML)

Este directorio contiene la configuración para levantar un clúster Kubernetes local usando [kind](https://kind.sigs.k8s.io/) y desplegar una aplicación nginx mediante manifiestos YAML puros.

## Contenido

| Archivo | Descripción |
|---|---|
| `kind-config.yaml` | Configuración del clúster: 1 control-plane + 2 workers |
| `deployment.yaml` | Deployment de nginx con 2 réplicas y estrategia RollingUpdate |
| `service.yaml` | Service de tipo NodePort que expone nginx en el puerto 80 |
| `ingress.yaml` | Recurso Ingress usando nip.io para acceso por nombre de host |

## Requisitos previos

- [Docker Desktop](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Instalación con Chocolatey (Windows)

```sh
choco install docker-desktop -y
choco install kind -y
choco install kubernetes-cli -y
```

### Verificar instalaciones

```sh
docker --version
kind version
kubectl version --client
```

## Topología del clúster

```
kind-config.yaml
├── control-plane  (1 nodo)
├── worker         (nodo 1)
└── worker         (nodo 2)
```

El archivo `kind-config.yaml` define esta topología:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

## Paso a paso

### 1. Crear el clúster

```sh
kind create cluster --name mi-cluster --config kind-config.yaml
```

Salida esperada:

```
Creating cluster "mi-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.33.1) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-mi-cluster"
```

### 2. Verificar el clúster

```sh
kubectl cluster-info --context kind-mi-cluster
kubectl get nodes
```

Salida esperada:

```
NAME                       STATUS   ROLES           AGE   VERSION
mi-cluster-control-plane   Ready    control-plane   2m    v1.33.1
mi-cluster-worker          Ready    <none>          2m    v1.33.1
mi-cluster-worker2         Ready    <none>          2m    v1.33.1
```

### 3. Desplegar nginx

```sh
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Verificar los recursos creados:

```sh
kubectl get all
```

```
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-f7b799bb8-fjq4l   1/1     Running   0          2m
pod/nginx-f7b799bb8-v6wd2   1/1     Running   0          2m

NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/nginx      NodePort    10.96.197.45   <none>        80:30602/TCP   10s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   2/2     2            2           2m
```

### 4. Acceder a la aplicación (NodePort)

Obtener la IP del nodo control-plane:

```sh
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mi-cluster-control-plane
```

Luego acceder desde el navegador usando la IP obtenida y el puerto NodePort asignado (ej: `30602`):

```
http://<IP_CONTROL_PLANE>:<NODEPORT>
```

### 5. Instalar Ingress Controller (opcional)

```sh
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml

# Etiquetar los nodos para que el ingress controller pueda desplegarse
kubectl label node --all ingress-ready=true
```

Esperar a que el pod del ingress controller esté en estado `Running`:

```sh
kubectl get pods -n ingress-nginx
```

### 6. Crear el recurso Ingress

El archivo `ingress.yaml` usa [nip.io](https://nip.io/) para resolver el nombre de host sin necesidad de DNS:

```sh
kubectl apply -f ingress.yaml
kubectl get ingress
```

Acceder desde el navegador o curl:

```sh
curl http://nginx.172.20.0.4.nip.io
```

> **Nota:** Reemplaza `172.20.0.4` con la IP real del nodo control-plane obtenida en el paso anterior.

## Eliminar el clúster

```sh
kind delete cluster --name mi-cluster
```

## Referencias

- [kind — Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes — Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [nip.io — Wildcard DNS](https://nip.io/)
