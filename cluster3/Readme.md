# Clúster Kind con Nginx Ingress Controller

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
- Installing tehcyx/kind v0.9.0...
- Installed tehcyx/kind v0.9.0 (self-signed, key ID F471C773A530ED1B)
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

## Despliegue de la Aplicación de Prueba

```bash
kubectl apply -f .\kubernetes\test-app.yaml

# Verificar despliegue
kubectl get pods
kubectl get ingress
kubectl get services

# Probar el acceso
curl localhost/hello

# Resultado (visualizar el cambio de Hostname en cada ejecución del comando curl, debido a que los pods estan balanceados por el ingress controller)
StatusCode        : 200
StatusDescription : OK
Content           : Hello, world!
                    Version: 1.0.0
                    Hostname: `hello-app-546c66f4c8-2sjfx`

RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Content-Length: 66
                    Content-Type: text/plain; charset=utf-8
                    Date: Tue, 12 Aug 2025 20:41:24 GMT

                    Hello, world!
                    Version: 1.0.0
                    Hostname: hello-app-546c66f4c8...
Forms             : {}
Headers           : {[Connection, keep-alive], [Content-Length, 66], [Content-Type, text/plain; charset=utf-8], [Date, Tue, 12 Aug 2025 20:41:24 GMT]}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 66
```

## Verificación de Componentes

```bash
# Estado del Ingress Controller
kubectl get pods -n ingress-nginx

NAME                                      READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-bd44dc47-hlk29   1/1     Running   0          4h55m
```

```bash
# Logs del Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

I0813 12:13:03.982706      11 event.go:377] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"hello-ingress", UID:"96e2dbca-1141-4008-8c8f-1b49478d5b7e", APIVersion:"networking.k8s.io/v1", ResourceVersion:"3208", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
W0813 12:13:07.306836      11 controller.go:1226] Service "default/hello-service" does not have any active Endpoint.
I0813 12:13:07.306892      11 controller.go:203] "Configuration changes detected, backend reload required"
I0813 12:13:07.326394      11 controller.go:223] "Backend successfully reloaded"
I0813 12:13:07.326607      11 event.go:377] Event(v1.ObjectReference{Kind:"Pod", Namespace:"ingress-nginx", Name:"ingress-nginx-controller-bd44dc47-hlk29", UID:"d8bbe5c4-91a2-443b-be44-80692140477d", APIVersion:"v1", ResourceVersion:"592", FieldPath:""}): type: 'Normal' reason: 'RELOAD' NGINX reload triggered due to a change in configuration
I0813 12:13:14.017108      11 status.go:304] "updating Ingress status" namespace="default" ingress="hello-ingress" currentValue=null newValue=[{"hostname":"localhost"}]
I0813 12:13:14.020891      11 event.go:377] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"hello-ingress", UID:"96e2dbca-1141-4008-8c8f-1b49478d5b7e", APIVersion:"networking.k8s.io/v1", ResourceVersion:"3233", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
W0813 12:13:14.020993      11 controller.go:1226] Service "default/hello-service" does not have any active Endpoint.
172.19.0.1 - - [13/Aug/2025:14:05:23 +0000] "GET /hello HTTP/1.1" 200 66 "-" "Mozilla/5.0 (Windows NT; Windows NT 10.0; es-ES) WindowsPowerShell/5.1.26100.4652" 159 0.004 [default-hello-service-80] [] 10.244.2.2:8080 66 0.004 200 8669b3e3bc0ab61346685310204f4e69
172.19.0.1 - - [13/Aug/2025:14:05:26 +0000] "GET /hello HTTP/1.1" 200 66 "-" "Mozilla/5.0 (Windows NT; Windows NT 10.0; es-ES) WindowsPowerShell/5.1.26100.4652" 135 0.002 [default-hello-service-80] [] 10.244.1.4:8080 66 0.003 200 018e5b46e9d8d745e239aea736455f10
```

```bash
# Estado del Ingress
kubectl describe ingress hello-ingress

Name:             hello-ingress
Labels:           <none>
Namespace:        default
Address:          localhost
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /hello   hello-service:80 (10.244.1.4:8080,10.244.2.2:8080)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:       <none>
```

## Limpieza de Infraestructura
```bash
# Eliminar aplicación
cd cluster3
kubectl delete -f .\kubernetes\test-app.yaml

# Eliminar infraestructura
cd cluster3
terraform destroy -auto-approve
```