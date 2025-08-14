# Creación de un clúster Kubernetes con kind

Este repositorio contiene una configuración personalizada para crear un clúster de Kubernetes local usando [kind](https://kind.sigs.k8s.io/).

## Requisitos previos

- Tener instalado [Docker](https://docs.docker.com/get-docker/)
- Tener instalado [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)

## Instalación

Instalación de Docker:
```sh
- choco install docker-desktop -y
```

Validación de la instalación:
```sh
$ docker --version
Docker version 28.3.2, build 578ccf6
```

Instalación de kind:
```sh
- choco install kind -y
```
Validación de la instalación:
```sh
$ kind version
kind v0.29.0 go1.24.2 windows/amd64
```
## Crear el clúster
Utlizaremos el directorio `cluster1` que contiene el archivo de configuración [`cluster1/config.yaml`](cluster1/config.yaml) para hacer el despliegue de un clúster de Kubernetes local.

Ejecuta el siguiente comando para crear el clúster usando el archivo de configuración [`cluster1/config.yaml`](cluster1/config.yaml):

```sh
kind create cluster --name mi-cluster --config=cluster1/config.yaml
```

Es muy sencillo crear cluster más complejos. Para ello simplemente creamos un fichero config.yaml donde vamos a declarar los nodos que tiene el cluster y los roles de cada uno de ellos, por ejemplo:

```sh
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```
Esto creará un clúster con un nodo de control y dos nodos worker, según la configuración especificada.

```sh
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: control-plane
- role: control-plane
- role: worker
- role: worker
- role: worker
```
Crearía un cluster con 6 nodos: 3 controladores en alta disponibilidad y 3 workers. 

Vamos a crear un cluster usando la primera configuración, para ello ejecutamos el siguiente comando:
```sh
❯ kind create cluster --name=mi-cluster --config=config.yaml
Creating cluster "mi-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.33.1) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-mi-cluster"
You can now use your cluster with:

kubectl cluster-info --context kind-mi-cluster

Thanks for using kind! 😊
```

## Verificar el clúster

Para verificar que el clúster se ha creado correctamente:

```sh
kubectl cluster-info --context kind-mi-cluster

Kubernetes control plane is running at https://127.0.0.1:55577
CoreDNS is running at https://127.0.0.1:55577/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```sh
kubectl get nodes
NAME                       STATUS   ROLES           AGE     VERSION
mi-cluster-control-plane   Ready    control-plane   2m22s   v1.33.1
mi-cluster-worker          Ready    <none>          2m12s   v1.33.1
mi-cluster-worker2         Ready    <none>          2m12s   v1.33.1
```

## Imagenes de Docker

Las imagenes de Docker usadas se pueden visualizar con el comando `docker images`.
```sh
docker images

REPOSITORY                             TAG       IMAGE ID       CREATED         SIZE
myngnix                                latest    b9adf3f36fa8   5 months ago    279MB
myapache-php                           v1        ff4ef1590c1c   5 months ago    739MB
portnavigator/port-navigator           1.1.0     1c3b1d792e15   22 months ago   235MB
nicobeck/registry-explorer-extension   0.0.2     2cc56b87573f   2 years ago     12.2MB
```

## Docker en ejecución

Los contenedores corriendo se pueden visualizar con el comando `docker ps`.

```sh
docker ps

CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                       NAMES
02f2de2a4ad4   kindest/node:v1.33.1   "/usr/local/bin/entr…"   4 minutes ago   Up 4 minutes   127.0.0.1:55577->6443/tcp   mi-cluster-control-plane
56cbbe112d3e   kindest/node:v1.33.1   "/usr/local/bin/entr…"   4 minutes ago   Up 4 minutes                               mi-cluster-worker
204d7c895386   kindest/node:v1.33.1   "/usr/local/bin/entr…"   4 minutes ago   Up 4 minutes                               mi-cluster-worker2
```

## Interactuando con el cluster kubernetes

Para interactuar con nuestro cluster hemos instalado la utilidad kubbectl. Podemos ver la información del clúster con el comando `kubectl cluster-info`. Tambien podemos ver la información de los nodos con el comando `kubectl get nodes`

```sh
$ kubectl get nodes
NAME                 STATUS   ROLES                  AGE     VERSION
kind-control-plane   Ready    control-plane,master   8m54s   v1.20.2
kind-worker          Ready    <none>                 8m15s   v1.20.2
kind-worker2         Ready    <none>                 8m15s   v1.20.2
```

Vamos a crear un despliegue en nuestro cluster a partir del fichero cluster1/deployment.yaml:

```sh
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: default
  labels:
    app: nginx
spec:
  revisionHistoryLimit: 2
  strategy:
    type: RollingUpdate
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - name: http
          containerPort: 80
```

Y un servicio de tipo NodePort a partir del fichero cluster1/service.yaml:

```sh
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: default
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    targetPort: http
  selector:
    app: nginx
```

Lo creamos y comprobamos los recursos que se han creado:

```sh
$ kubectl apply -f deployment.yaml 
deployment.apps/nginx created

 kubectl get all
   NAME                        READY   STATUS    RESTARTS   AGE
## pod/nginx-f7b799bb8-fjq4l   1/1     Running   0          107s
## pod/nginx-f7b799bb8-v6wd2   1/1     Running   0          107s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5m30s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   2/2     2            2           107s

NAME                              DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-f7b799bb8   2         2         2       107s
```

```sh
$ kubectl create -f service.yaml 
service/nginx created


$ kubectl get all
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-f7b799bb8-fjq4l   1/1     Running   0          4m21s
pod/nginx-f7b799bb8-v6wd2   1/1     Running   0          4m21s

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        8m4s
service/nginx        NodePort    10.96.197.45   <none>        80:30602/TCP   3s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   2/2     2            2           4m21s

NAME                              DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-f7b799bb8   2         2         2       4m21s
```

En este ejemplo deberíamos acceder a la `ip del nodo controlador y al puerto 30602` para acceder a la aplicación. Para obtener la ip del contenedor podemos ejecutar:

```sh
	$ docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane

    172.19.0.2
```

Por lo tanto desde un navegador podemos acceder a esa ip y al puerto asignado por el servicio, para ver la aplicación:
    http://172.19.0.2:30602


tambienm podemos ver los recursos con el comando `kubectl get` y las distintas opciones que podemos usar:

```sh
❯ kubectl get pods
NAME                    READY   STATUS    RESTARTS   AGE
nginx-f7b799bb8-fjq4l   1/1     Running   0          27m
nginx-f7b799bb8-v6wd2   1/1     Running   0          27m
```

```sh
❯ kubectl get services
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        30m
nginx        NodePort    10.96.197.45   <none>        80:30602/TCP   22m
```

```sh
❯ kubectl get deployments
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   2/2     2            2           27m
```

```sh
❯ kubectl get replicasets
NAME              DESIRED   CURRENT   READY   AGE
nginx-f7b799bb8   2         2         2       27m
```

## Instalando un controlador ingress a nuestro cluster

Tenemos varias opciones en la documentación para instalar un controlador ingress en nuestro cluster. Nosotros vamos a intalar un nginx ingres, para ello ejecutamos la siguiente instrucción:
```sh
$ kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml
```
Esto creará un namespace llamado ingress-nginx con todos los recursos necesarios para que funcione el proxy inverso.

Cuando he ejecutado la instrucción anterior, me he dado cuenta que el pod que se debe crear para que funcione nginx se que da en estado pending, buscando información he llegado a la conclusión de que no encuentra nodos afines para desplegarse, ya que necesita que los nodos estén etiquetados con la etiqueta ingress-ready=true, para etiquetar los nodos del cluster ejecutamos:

```sh
$ kubectl label node --all  ingress-ready=true
```
Y al cabo de unos segundos ya tenemos el pod ejecutándose.

A continuación podemos hacer una prueba de un recurso ingress usando el fichero ingress.yaml con el siguietne contenido:

```sh
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: nginx.172.20.0.4.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```
Como puedes observar para indicar el nombre del host, he usado el dominio nip.io para no usar resolución estática. Creamos el ingress, comprobamos que se ha creado y accedemos a la página utilizando el nombre indicado:

```sh
$ kubectl create -f ingress.yaml 
ingress.networking.k8s.io/nginx created

$ kubectl get ingress
NAME    CLASS    HOSTS                     ADDRESS   PORTS   AGE
nginx   <none>   nginx.172.20.0.4.nip.io             80      7s

$ curl http://nginx.172.20.0.4.nip.io
```

## Borrar el clúster

Cuando ya no necesites el clúster, puedes eliminarlo con:

```sh
kind delete cluster --name mi-cluster
```
 ## REFERENCIAS
 - https://kind.sigs.k8s.io/docs/user/quick-start/
 - https://www.josedomingo.org/pledin/2021/02/kubernetes-con-kind/