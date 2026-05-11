# Kind — Kubernetes local con Kind y Terraform

Este repositorio contiene tres enfoques progresivos para levantar clústeres Kubernetes locales usando [kind (Kubernetes IN Docker)](https://kind.sigs.k8s.io/), desde manifiestos YAML manuales hasta infraestructura como código con Terraform e Ingress Controller automatizado.

## Estructura del repositorio

```
kind/
├── cluster1/          # Kind manual con manifiestos YAML (nginx)
├── cluster2/          # Kind + Terraform básico (1 control-plane + 1 worker)
└── cluster3/          # Kind + Terraform completo (Ingress Controller + app de prueba)
```

## Resumen de cada carpeta

### cluster1 — Kind manual con YAML

Enfoque más directo: se crea el clúster con el CLI de `kind` y se despliegan los recursos con `kubectl apply`.

| Componente | Detalle |
|---|---|
| Herramienta | `kind` CLI + `kubectl` |
| Topología | 1 control-plane + 2 workers |
| Aplicación | nginx (Deployment + Service NodePort + Ingress) |
| Ingress | nginx ingress controller instalado manualmente |

Ideal para aprender los conceptos básicos de Kind y Kubernetes sin capas adicionales de abstracción.

→ [Ver README de cluster1](cluster1/README.md)

---

### cluster2 — Kind + Terraform básico

Introduce **Terraform** como herramienta de infraestructura como código para gestionar el ciclo de vida del clúster Kind.

| Componente | Detalle |
|---|---|
| Herramienta | Terraform + provider `tehcyx/kind` v0.9.0 |
| Topología | 1 control-plane + 2 worker |
| Aplicación | Ninguna (solo infraestructura) |
| Ingress | No incluido |

Ideal para entender cómo reemplazar los comandos manuales de `kind` por un flujo declarativo y reproducible.

→ [Ver README de cluster2](cluster2/Readme.md)

---

### cluster3 — Kind + Terraform completo con Ingress y app de prueba

La configuración más completa del repositorio. Combina Terraform, Kind, Nginx Ingress Controller instalado automáticamente y una aplicación de prueba con balanceo de carga.

| Componente | Detalle |
|---|---|
| Herramienta | Terraform + providers `tehcyx/kind` v0.9.0, `hashicorp/kubernetes` v2.33.0, `hashicorp/null` v3.2.4 |
| Topología | 1 control-plane + 2 workers |
| Port mappings | Puertos 80 y 443 del host mapeados al control-plane |
| Ingress Controller | Nginx, instalado automáticamente vía `null_resource` |
| Aplicación | `hello-app` (Google sample) con 2 réplicas, balanceo de carga visible |
| Variables | Nombre del clúster y ruta del kubeconfig configurables |
| Outputs | Nombre, kubeconfig path, workers, estado ingress |

Ideal para simular un entorno de desarrollo completo con acceso HTTP/HTTPS desde `localhost`.

→ [Ver README de cluster3](cluster3/Readme.md)

---

## Comparativa rápida

| | cluster1 | cluster2 | cluster3 |
|---|:---:|:---:|:---:|
| Herramienta principal | kind CLI | Terraform | Terraform |
| Control-plane | 1 | 1 | 1 |
| Workers | 2 | 1 | 2 |
| Ingress Controller | Manual | ✗ | Automático |
| Port mapping al host | ✗ | ✗ | ✓ (80/443) |
| Aplicación de prueba | nginx | ✗ | hello-app |
| IaC | ✗ | ✓ | ✓ |
| Complejidad | Baja | Media | Alta |

## Requisitos generales

- [Docker Desktop](https://docs.docker.com/get-docker/) — motor de contenedores requerido por Kind
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) — para cluster1
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0.0 — para cluster2 y cluster3
- [kubectl](https://kubernetes.io/docs/tasks/tools/) — para interactuar con cualquier clúster

### Instalación rápida con Chocolatey (Windows)

```sh
choco install docker-desktop -y
choco install kind -y
choco install terraform -y
choco install kubernetes-cli -y
```

## Flujo recomendado de aprendizaje

```
cluster1  →  cluster2  →  cluster3
  (YAML)      (IaC básico)   (IaC completo + Ingress)
```

Empezar por `cluster1` para entender los fundamentos, luego avanzar a `cluster2` para introducir Terraform, y finalmente `cluster3` para un entorno de desarrollo local completo.

## Actualización de versiones

### Kind CLI (herramienta local)

Para verificar la versión instalada y las versiones disponibles:

```sh
# Versión instalada
choco list kind

# Versiones disponibles
choco info kind

# Actualizar a la última versión
choco upgrade kind -y
```

La versión de Kind que se usa en **cluster1** (enfoque manual con YAML) es la que tengas instalada localmente. No hay ningún archivo en el repositorio que especifique esta versión; se usa directamente el binario de `kind`.

### Proveedor Terraform `tehcyx/kind`

Los clusters **cluster2** y **cluster3** utilizan el proveedor Terraform [tehcyx/kind](https://registry.terraform.io/providers/tehcyx/kind/latest) para gestionar los clústeres Kind desde Terraform. La versión se especifica en el archivo:

- `cluster3/versions.tf` — para cluster3
- `cluster2/main.tf` — para cluster2

Para actualizar la versión del proveedor:

1. Consultar la última versión disponible en el [Terraform Registry](https://registry.terraform.io/providers/tehcyx/kind/latest)
2. Modificar el archivo correspondiente (por ejemplo, cambiar `version = "0.9.0"` a `version = "0.11.0"`)
3. Ejecutar en el directorio del cluster:

```sh
terraform init -upgrade
```

Esto descargará e instalará la nueva versión del proveedor.

## Referencias

- [kind — Documentación oficial](https://kind.sigs.k8s.io/)
- [Terraform — Documentación oficial](https://developer.hashicorp.com/terraform/docs)
- [Provider tehcyx/kind](https://registry.terraform.io/providers/tehcyx/kind/latest)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [kubectl — Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
