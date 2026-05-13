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
```

Salida esperada:
```sh
Kubernetes control plane is running at https://127.0.0.1:64634
CoreDNS is running at https://127.0.0.1:64634/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```sh
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

Verificar los pods creados:

```sh
kubectl get pods
```

```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-545cdc766-8smwj   1/1     Running   0          18s
nginx-545cdc766-hpxdm   1/1     Running   0          18s
```

Verificar los servicios:
```sh
kubectl get services
```

```
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   9m31s
```
Una vez ejecutado el comando | `kubectl apply -f service.yaml` | se agregará el servicio ngnix *:

```
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        11m
nginx *      NodePort    10.96.189.159   <none>        80:30891/TCP   5s
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
172.18.0.3
```

Obtener las IPs de mis workers:
```sh
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mi-cluster-worker
172.18.0.2

```sh
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mi-cluster-worker2
172.18.0.4
```

__Ver todos los nodos con su IP y el NodePort__:

```sh
kubectl get nodes -o wide

NAME                       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION                     CONTAINER-RUNTIME
mi-cluster-control-plane   Ready    control-plane   12m   v1.35.0   172.18.0.3    <none>        Debian GNU/Linux 12 (bookworm)   6.6.87.2-microsoft-standard-WSL2   containerd://2.2.0
mi-cluster-worker          Ready    <none>          12m   v1.35.0   172.18.0.2    <none>        Debian GNU/Linux 12 (bookworm)   6.6.87.2-microsoft-standard-WSL2   containerd://2.2.0
mi-cluster-worker2         Ready    <none>          12m   v1.35.0   172.18.0.4    <none>        Debian GNU/Linux 12 (bookworm)   6.6.87.2-microsoft-standard-WSL2   containerd://2.2.0
```

Si querés acceder desde tu máquina local (fuera del clúster Kind), necesitás mapear un puerto de tu host al contenedor Docker del nodo. Kind por defecto no expone puertos de los nodos workers. Una opción es usar `port-forward`:

```sh
kubectl port-forward svc/nginx 8080:80
```

Y luego acceder desde un navegador.  `http://localhost:8080`.

Nota: Se puede hacer kill del proceso `kubectl port-forward svc/nginx 8080:80` para finalizar el port-forward.

### 5. Instalar el NGINX Ingress Controller en Kind (opcional)

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
# Este manifiesto está __específicamente adaptado para Kind__ y configura todo lo necesario (namespace, deployment, service tipo NodePort, etc.).

namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created


# Etiquetar los nodos para que el ingress controller pueda desplegarse
# Kind requiere que los nodos tengan una etiqueta especial para que el Ingress Controller pueda desplegarse correctamente:
kubectl label node --all ingress-ready=true

node/mi-cluster-control-plane not labeled
node/mi-cluster-worker not labeled
node/mi-cluster-worker2 not labeled
```

Esperar a que el Ingress Controller esté listo
```sh
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

pod/ingress-nginx-controller-56dc4b4c6-mwlqp condition met
```

Verificar que el pod este corriendo

```sh
kubectl get pods -n ingress-nginx
```

Deberías ver algo como:
```sh
NAME                                       READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-xxxxxxxxx-xxxxx   1/1     Running   0          7m6s
```

### 6. Crear el recurso Ingress

El archivo `ingress.yaml` usa [nip.io](https://nip.io/) para resolver el nombre de host sin necesidad de DNS.

Antes de aplicarlo, asegurate de que el `host` contenga la IP real del nodo control-plane:

Obtener la IP del nodo control-plane:
```sh
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mi-cluster-control-plane
```

Salida esperada (la IP puede variar):
```
172.18.0.3
```

Actualizar el host en `ingress.yaml` con la IP obtenida (ej: `nginx.172.18.0.3.nip.io`):

```yaml
spec:
  rules:
  - host: nginx.172.18.0.3.nip.io
```

Aplicar el recurso Ingress:
```sh
kubectl apply -f ingress.yaml
```

Verificar que se creó correctamente:
```sh
kubectl get ingress
```

Salida esperada:
```
NAME    CLASS    HOSTS                     ADDRESS     PORTS   AGE
nginx   <none>   nginx.172.18.0.3.nip.io   localhost   80      6m
```

> El campo `ADDRESS` muestra `localhost` porque Kind asigna el Ingress Controller en el nodo control-plane accesible desde el host.

### 7. Probar el acceso vía Ingress

Hay dos formas de probar el Ingress:

#### Opción A — Usando port-forward (recomendado desde Windows)

El servicio del Ingress Controller expone los puertos HTTP (80) y HTTPS (443) mapeados a NodePorts. Con port-forward podés acceder desde tu máquina local:

```sh
# En una terminal
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
```

En otra terminal, probar con curl usando el header `Host`:
```sh
curl -H "Host: nginx.172.18.0.3.nip.io" http://localhost:8080
```

O desde el navegador (con el port-forward activo solamente):
```
http://localhost:8080
```

#### Opción B — Usando la IP del nodo (dentro de la red Docker)

```sh
curl -H "Host: nginx.172.18.0.3.nip.io" http://172.18.0.3:30394
```

#### ¿Por qué se usa el header `Host`?

El recurso Ingress define un `host` específico (`nginx.172.18.0.3.nip.io`). El Ingress Controller nginx enruta el tráfico según el header `Host` de la petición HTTP. Al enviar `-H "Host: nginx.172.18.0.3.nip.io"`, le indicamos al Ingress Controller a qué servicio debe dirigir el tráfico.

> **Nota sobre nip.io:** El dominio `nginx.172.18.0.3.nip.io` resuelve automáticamente a la IP `172.18.0.3` gracias al servicio DNS público [nip.io](https://nip.io/). Esto evita tener que editar el archivo `/etc/hosts` o configurar un DNS local.

#### Salida esperada de curl

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</html>
```

### 8. Detener el port-forward

Para finalizar el `port-forward`, presioná `Ctrl + C` en la terminal donde se está ejecutando. Si se ejecutó en segundo plano:

```sh
# En Windows (cmd/PowerShell)
tasklist | findstr kubectl
taskkill /PID <PID> /F

# En WSL / Linux / macOS
pkill -f "kubectl port-forward"
```

## Eliminar el clúster

```sh
kind delete cluster --name mi-cluster
```

## Referencias

- [kind — Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes — Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [nip.io — Wildcard DNS](https://nip.io/)
