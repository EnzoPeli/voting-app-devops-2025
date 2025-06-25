# DevOps Voting-app 2025

## Contenidos

1. [Visión General](#visión-general)  
2. [Estructura del Repositorio](#estructura-del-repositorio)
3. [Estrategia de Branching](#estrategia-de-branching)
4. [Kanban & Flujo de Trabajo](#kanban--flujo-de-trabajo)  
5. [Infraestructura como Código (IaC)](#infraestructura-como-código-iac)  
6. [CI/CD](#cicd)  
7. [Containerización & Docker Compose](#containerización--docker-compose)  
8. [Serverless](#serverless)  
9. [Observabilidad](#observabilidad)  
10. [Próximos Pasos](#próximos-pasos)



## Visión General

> Este proyecto busca aplicar DevOps, para asegurar despliegues fiables en tres ambientes (Dev, Test y Prod). 
> Abarca:
> - Infraestructura como Código con Terraform  
> - Pipelines de CI/CD en GitHub Actions  
> - Containerización de microservicios y orquestación  
> - Pruebas de calidad y análisis estático  
> - Servicios Serverless para automatizaciones  
> - Observabilidad y alertas  
> - Documentación y presentación de la solución 
> - Control de versiones y estrategia de branching

## Estructura del Repositorio



```text
voting-app-devops-2025/
├── app/            # Código fuente de la Voting-app
├── infra/          # Módulos y root de Terraform
├── k8s/            # Manifiestos de Kubernetes para despliegue en EKS
├── .github/        # Workflows de GitHub Actions
├── serverless/     # Funciones Lambda
├── docs/           # Imágenes, diagramas y guías adicionales
└── README.md       # Documentación principal del proyecto
```

## Estrategia de Branching

Para gestionar los tres entornos (Dev, Test y Prod) usamos un flujo de ramas:

- **Ramas principales**  
  - `develop`: integraciones y despliegue automático a Dev.  
  - `test`: despliegue a Test tras aprobar quality gates.  
  - `main`: despliegue a Prod, puede usarse con tagging semántico (`vX.Y.Z`).

- **Feature branches**  
  - Se crean desde `develop`:  
    ```bash
    git checkout develop
    git checkout -b feature/<epic>-<descripción>
    ```
  - Nombre: `feature/<epic>-<descripción-corta>` (p.ej. `feature/docker-build`).  
  - Al terminar, push y PR a `develop`; debe pasar el CI de Dev y la revisión de un reviewer.

- **Promoción de cambios**  
  1. **Dev → Test**: abrir PR `develop → test`, aprobar gates en Test (pruebas de integración, carga, etc.), mergear.  
  2. **Test → Prod**: abrir PR `test → main`, aprobar gates de seguridad y despliegue, mergear y taguear.

## Kanban & Flujo de Trabajo

El proyecto utiliza un tablero Kanban en GitHub Projects con las siguientes columnas:

- **Backlog**: Tareas identificadas y pendientes de priorizar.  
- **To Do**: Tareas priorizadas y listas para arrancar.  
- **In Progress**: Tareas en desarrollo.  
- **Review**: Tareas completadas que esperan revisión o validación.  
- **Done**: Tareas finalizadas y documentadas.

### Estado Inicial

![Estado inicial del Kanban](docs/initial-kanban.png)

### Estado 2

![Estado 2 del Kanban](docs/second-kanban.png)

Cada tarjeta del tablero corresponde a un Issue en GitHub, etiquetado con su Épica y prioridad (P0–P2). El flujo de trabajo es:

1. Se crea el Issue en **Backlog**.  
2. Se pasa a **To Do** cuando se prioriza para el próximo sprint.  
3. Al iniciar trabajo, se mueve a **In Progress**.  
4. Al completar, se mueve a **Review** y se abre el Pull Request asociado.  
5. Tras la aprobación y merge, se marca como **Done** y se documenta (capturas, actualizaciones en `docs/` o en el README).




## Infraestructura como Código (IaC)

La infraestructura se define con Terraform en la carpeta `infra/`, estructurada de la siguiente forma:

```text
infra/
├── modules/
│   ├── ecr-repo/         # Módulo para crear el repositorio ECR
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/          # Módulo de red (VPC, subnets, routing)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security_group/   # Módulo de Security Group (HTTP/SSH)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks_cluster/      # Módulo para crear el cluster EKS
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── main.tf               # Root module: orquesta los módulos
├── variables.tf          # Variables globales (env, región, CIDRs, etc.)
├── outputs.tf            # Outputs del proyecto (vpc_id, sg_id, ecr_url, …)
├── dev.tfvars            # Valores de variables para entorno Dev
└── tfplan                # (opc.) Plan generado para revisión
```

### Módulos

#### ecr-repo (infra/modules/ecr-repo)
- Define repositorios AWS ECR para los servicios
- Variables:
  - `name`: Nombre del repositorio ECR
  - `tags`: Etiquetas a aplicar al repositorio (opcional)
- Outputs: `repository_url`

#### network (infra/modules/network)
- Crea la VPC y dos subnets públicas
- Variables:
  - `vpc_cidr`: CIDR block para la VPC (default: "10.0.0.0/16")
  - `public_subnets_cidrs`: Lista de CIDR blocks para subnets (default: ["10.0.1.0/24", "10.0.2.0/24"])
  - `region`: Región de AWS (default: "us-east-1")
  - `availability_zones`: Lista de AZs para las subnets
- Outputs: `vpc_id`, `public_subnet_ids`

#### security_group (infra/modules/security_group)
- Crea un Security Group para los servicios
- Variables:
  - `vpc_id`: ID de la VPC donde se creará el SG
  - `sg_name`: Nombre del Security Group (default: "sg-voting-app")
  - `ingress_rules`: Lista de reglas de ingreso configurables (puertos, protocolos, CIDRs)
- Outputs: `sg_id`

#### eks_cluster (infra/modules/eks_cluster)
- Crea un cluster EKS y un grupo de nodos para ejecutar la aplicación, 
- Variables:
  - `cluster_name`: Nombre del cluster EKS
  - `node_group_name`: Nombre del grupo de nodos
  - `cluster_role_arn`: ARN del rol IAM para el plano de control
  - `node_role_arn`: ARN del rol IAM para los nodos trabajadores
  - `subnet_ids`: Lista de IDs de subnets donde se desplegará el cluster
  - `ec2_ssh_key_name`: Nombre de la clave SSH para acceso a los nodos
  - `instance_types`: Tipos de instancia para los nodos (default: ["t3.small"])
  - `desired_capacity`, `min_capacity`, `max_capacity`: Configuración de auto-scaling
  - `node_security_group_ids`: IDs de los security groups para los nodos
- Outputs: `cluster_name`, `cluster_endpoint`, `cluster_certificate_authority`, `node_group_name`

### Root Module

En `infra/main.tf` se invocan los módulos y se pasan las variables:

```hcl
# Repositorio ECR para el servicio vote
module "ecr_vote" {
  source = "./modules/ecr-repo"
  name   = "voting-app-vote"
  tags   = var.tags
}

# Repositorio ECR para el servicio result
module "ecr_result" {
  source = "./modules/ecr-repo"
  name   = "voting-app-result"
  tags   = var.tags
}

# Repositorio ECR para el servicio seed-data
module "ecr_seed" {
  source = "./modules/ecr-repo"
  name   = "voting-app-seed-data"
  tags   = var.tags
}

# Repositorio ECR para el servicio worker
module "ecr_worker" {
  source = "./modules/ecr-repo"
  name   = "voting-app-worker"
  tags   = var.tags
}

# Modulo de Network
module "network" {
  source               = "./modules/network"
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidrs = var.public_subnets_cidrs
}

# Modulo de Security Group
module "security_group" {
  source = "./modules/security_group"
  vpc_id = module.network.vpc_id
}

# Modulo de EKS Cluster
module "eks_cluster" {
  source = "./modules/eks_cluster"

  cluster_name = "voting-app-eks"
  node_group_name = "voting-app-node-group"
  cluster_role_arn = data.aws_iam_role.lab_role.arn
  node_role_arn = data.aws_iam_role.lab_role.arn
  subnet_ids = module.network.public_subnet_ids
  ec2_ssh_key_name = "voting-app-ssh-key"
  instance_types = ["t3.small"]
  desired_capacity = 2
  min_capacity = 1
  max_capacity = 3
  tags = var.tags
}


```

Los outputs de todos los módulos se exponen en `infra/outputs.tf`.

### Backend Remoto

El estado remoto de Terraform se configura directamente en `infra/main.tf` con un backend S3:

```hcl
terraform {
  backend "s3" {
    bucket         = "voting-app-terraform-state-177816"
    key            = "voting-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

### Creacion de Bucket para Terraform State (CLI)

Para crear el bucket y la tabla de DynamoDB para el estado de Terraform, puedes usar el siguiente script:
```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export TF_STATE_BUCKET=voting-app-terraform-state-177816
export DYNAMO_LOCK_TABLE=terraform-locks

# Crear el bucket para el estado de Terraform
aws s3 mb s3://$TF_STATE_BUCKET --region $AWS_REGION

# Crear la tabla de DynamoDB para el locking
aws dynamodb create-table \
  --table-name $DYNAMO_LOCK_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION

```

- **bucket**: `voting-app-terraform-state-177816`
- **key**: `voting-app/terraform.tfstate`
- **region**: `us-east-1`
- **dynamodb_table**: `terraform-locks` (para locking de estado)

### Estado Actual en AWS

![Infraestructura Dev](docs/infra-dev.png)

> **Nota**: La captura anterior muestra la VPC y sus subnets en AWS Console, confirmando que Terraform aplicó correctamente los recursos en el entorno Dev.

### Variables por Ambiente

- `infra/dev.tfvars`
- `infra/test.tfvars` (pendiente)
- `infra/prod.tfvars` (pendiente)

### Comandos Útiles

```bash
cd infra
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -auto-approve -var-file=dev.tfvars
```


## CI/CD

La aplicación utiliza GitHub Actions para automatizar el proceso de CI/CD, con flujos de trabajo específicos para cada ambiente.

### Pipelines de CI/CD

El proyecto implementa una estrategia de CI/CD con pipelines unificados por ambiente:

#### Flujo de Despliegue Automatizado

El proceso de CI/CD está configurado para desplegar automáticamente en el entorno correspondiente:

1. **Workflow [ci-dev.yml]**:
   - Se ejecuta al hacer push a la rama `develop`
   - Realiza análisis estático de código
   - Aplica la infraestructura con Terraform usando `dev.tfvars`
   - Construye y publica las imágenes Docker con tag `:dev`
   - Despliega la aplicación en el namespace `dev`

2. **Workflow [ci-test.yml]**:
   - Se ejecuta al hacer push a la rama `test`
   - Ejecuta pruebas de integración
   - Aplica la infraestructura con Terraform usando `test.tfvars`
   - Construye y publica las imágenes Docker con tag `:test`
   - Despliega la aplicación en el namespace `test`

3. **Workflow [ci-prod.yml]**:
   - Se ejecuta al hacer push a la rama `main` o tags `v*.*.*`
   - Aplica la infraestructura con Terraform usando `prod.tfvars`
   - Construye y publica las imágenes Docker con tag `:prod`
   - Despliega la aplicación en el namespace `prod`
   - Utiliza protecciones adicionales del entorno `production`

Para más detalles sobre los workflows, consulta [docs/workflows.md](docs/workflows.md).

#### Ventajas de este Enfoque

- **Aislamiento**: Cada entorno opera de forma independiente sin interferir con otros
- **Consistencia**: Mismos manifiestos para todos los entornos, reduciendo duplicación
- **Trazabilidad**: Clara separación entre versiones de desarrollo, test y producción
- **Facilidad de gestión**: Comandos kubectl pueden filtrarse por namespace
- **Seguridad**: Posibilidad de aplicar diferentes políticas de RBAC por entorno
- **Secuencia garantizada**: Los jobs se ejecutan en un orden específico, asegurando dependencias correctas
---

> **Variables / Secrets** necesarios:  
> - `AWS_ACCESS_KEY_ID`  
> - `AWS_SECRET_ACCESS_KEY`  
> - `AWS_SESSION_TOKEN`  
> - `AWS_DEFAULT_REGION`

## Containerización & Docker Compose

Los microservicios de la Voting-app se empaquetan en contenedores Docker y se orquestan localmente con Docker Compose.

### Validación de Dockerfiles

- **app/vote**
  - Base: `python:3.11-slim`
  - Expone puerto `80` (mapeado a `8080` en host)
  - Health-check: `curl -f http://localhost`

- **app/result**
  - Base: Node.js
  - Expone puerto `80` (mapeado a `8081` en host)

- **app/seed-data**
  - Job que carga datos iniciales en la base de datos
  - En perfil `seed` separado (no se ejecuta por defecto, usar `--profile seed` para activarlo)

- **app/worker**
  - Base: .NET
  - Depende de `redis` y `db`
  - No expone puertos HTTP

### Levantar el stack local

Se proporciona un `docker-compose.yml` en `app/`.

```bash
# Configurar variables de entorno
cd app/
cp .env.example .env    # Copiar plantilla de variables de entorno

# Levantar servicios principales
docker compose up --build -d

# Ver logs de servicios
docker compose logs -f vote result worker

# Ejecutar seed-data (opcional)
docker compose --profile seed up --build -d seed

# Detener y limpiar
docker compose down --volumes
```

## Orquestación con Kubernetes (EKS)

La aplicación está configurada para ser desplegada en un cluster de Kubernetes gestionado por AWS (EKS). Los manifiestos se encuentran en el directorio `k8s/`, organizados por componente.
Se utiliza kubectl para desplegar la aplicación en el cluster EKS.

### Estructura de Manifiestos

```text
k8s/
├── db/                # Base de datos PostgreSQL
│   ├── 01-deployment.yaml
│   └── 02-service.yaml
├── redis/             # Cola de mensajes Redis
│   ├── 01-deployment.yaml
│   └── 02-service.yaml
├── result/            # Frontend de resultados
│   ├── 01-deployment.yaml
│   └── 02-service.yaml
├── seed-data/         # Job para cargar datos iniciales
│   └── job.yaml
├── vote/              # Frontend de votación
│   ├── 01-deployment.yaml
│   └── 02-service.yaml
└── worker/            # Procesador de votos
    └── 01-deployment.yaml
```

### Decisiones de Arquitectura

#### Exposición de Servicios con LoadBalancer

Para la exposición de los servicios de la aplicación (Vote y Result), se ha optado por utilizar servicios de tipo LoadBalancer en lugar de un Ingress Controller por las siguientes razones:

1. **Simplicidad operativa**: Cada aplicación tiene su propio punto de entrada con su propia dirección IP/DNS, lo que simplifica la configuración y el diagnóstico de problemas.

2. **Compatibilidad con las aplicaciones**: Las aplicaciones Vote y Result están diseñadas para ejecutarse en la raíz (`/`), lo que causaba conflictos al intentar exponerlas bajo diferentes rutas (`/vote` y `/result`) mediante Ingress.

3. **Evitar problemas con recursos estáticos**: Al usar LoadBalancer, cada aplicación se ejecuta en su propia raíz, evitando problemas con las rutas relativas de los recursos estáticos (CSS, JavaScript).

4. **Aislamiento**: Cada servicio está completamente aislado, lo que facilita la gestión independiente de cada componente.

**Funcionamiento**:

- Cada servicio (Vote y Result) tiene su propio balanceador de carga AWS que recibe tráfico externo.
- El tráfico se dirige directamente a los pods correspondientes sin necesidad de reescritura de rutas.
- Los usuarios acceden a cada aplicación a través de diferentes URLs (direcciones IP o DNS asignadas por AWS).
- Internamente, los servicios Redis y PostgreSQL se mantienen como ClusterIP, accesibles solo dentro del clúster.

**Consideraciones de costo**: Esta arquitectura implica múltiples balanceadores de carga, lo que puede aumentar los costos en AWS. Para entornos de desarrollo o pruebas donde el costo es una preocupación, se podría considerar el uso de servicios NodePort o un único Ingress Controller con configuración adecuada.

### Componentes de la Aplicación

1. **vote**: Frontend para votar (Python)
   - Deployment: 1 réplica con imagen desde ECR
   - Service: Tipo LoadBalancer que expone el puerto 80 externamente

2. **redis**: Cola de mensajes
   - Deployment: 1 réplica con imagen oficial de Redis
   - Service: Expone el puerto 6379 internamente

3. **worker**: Procesador de votos (C#)
   - Deployment: 1 réplica con imagen desde ECR
   - Conecta Redis con PostgreSQL
   - No expone puertos (proceso en segundo plano)

4. **db**: Base de datos PostgreSQL
   - Deployment: 1 réplica con imagen oficial de PostgreSQL
   - Volumen: emptyDir (almacenamiento efímero, los datos se pierden al reiniciar el pod)
   - Service: Expone el puerto 5432 internamente

5. **result**: Frontend para mostrar resultados (Node.js)
   - Deployment: 1 réplica con imagen desde ECR
   - Service: Tipo LoadBalancer que expone el puerto 80 externamente

6. **seed-data**: Job para cargar datos iniciales
   - Job: Ejecuta una vez para inicializar la base de datos

### Despliegue en EKS

Para desplegar la aplicación en el cluster EKS:

```bash
# Configurar kubectl para conectar con el cluster EKS
aws eks update-kubeconfig --name voting-cluster --region us-east-1

# Verificar conexión
kubectl get nodes

# Desplegar componentes de infraestructura
kubectl apply -f k8s/db/
kubectl apply -f k8s/redis/

# Desplegar aplicación
kubectl apply -f k8s/worker/
kubectl apply -f k8s/vote/
kubectl apply -f k8s/result/

# Cargar datos iniciales (opcional)
kubectl apply -f k8s/seed-data/

# Verificar estado
kubectl get pods
kubectl get services
kubectl get ingress
```

> **Nota**: Los Ingress requieren un controlador de Ingress como NGINX Ingress Controller instalado en el cluster.

### Estrategia de Despliegue Multi-entorno

La aplicación está diseñada para ser desplegada en múltiples entornos (desarrollo, test, producción) utilizando una estrategia de parametrización basada en namespaces de Kubernetes.

#### Separación por Namespaces

Utilizamos namespaces de Kubernetes para aislar los entornos:

- **Namespace `dev`**: Entorno de desarrollo, desplegado automáticamente desde la rama `develop`
- **Namespace `test`**: Entorno de test, desplegado desde la rama `test`
- **Namespace `prod`**: Entorno de producción, desplegado desde la rama `main`

#### Parametrización de Manifiestos

Los manifiestos de Kubernetes están parametrizados usando variables de entorno:

1. **Variable `${NAMESPACE}`**: Se utiliza para:
   - Definir el namespace en cada recurso
   - Especificar la etiqueta de imagen correcta (dev/prod/test)

2. **Proceso de reemplazo de variables**:
   - El script `scripts/apply-manifests.sh` utiliza `envsubst` para reemplazar las variables antes de aplicar los manifiestos
   - Esto permite mantener un único conjunto de manifiestos para todos los entornos

```bash
# Ejemplo de uso del script
NAMESPACE=dev ./scripts/apply-manifests.sh  # Para desarrollo
NAMESPACE=test ./scripts/apply-manifests.sh  # Para test
NAMESPACE=prod ./scripts/apply-manifests.sh  # Para producción
```

#### Flujo de Despliegue Automatizado

El proceso de CI/CD está configurado para desplegar automáticamente en el entorno correspondiente:

1. **Workflow `terraform-dev.yml`**:
   - Se ejecuta al hacer push a la rama `develop`
   - Aplica la infraestructura con Terraform usando `dev.tfvars`
   - Despliega la aplicación en el namespace `dev` con las imágenes etiquetadas como `dev`

2. **Workflow `terraform-test.yml`**:
   - Se ejecuta al hacer push a la rama `test`
   - Aplica la infraestructura con Terraform usando `test.tfvars`
   - Despliega la aplicación en el namespace `test` con las imágenes etiquetadas como `test`

3. **Workflow `terraform-prod.yml`**:
   - Se ejecuta al hacer push a la rama `main`
   - Aplica la infraestructura con Terraform usando `prod.tfvars`
   - Despliega la aplicación en el namespace `prod` con las imágenes etiquetadas como `prod`



#### Ventajas de este Enfoque

- **Aislamiento**: Cada entorno opera de forma independiente sin interferir con otros
- **Consistencia**: Mismos manifiestos para todos los entornos, reduciendo duplicación
- **Trazabilidad**: Clara separación entre versiones de desarrollo, test y producción
- **Facilidad de gestión**: Comandos kubectl pueden filtrarse por namespace
- **Seguridad**: Posibilidad de aplicar diferentes políticas de RBAC por entorno

> **Nota**: El archivo `.env` contiene las variables de entorno necesarias para los servicios:
> - Credenciales de PostgreSQL
> - Configuración de Redis
> - Puertos de servicios
> Se creo  el .evn como muestra de una practica de seguridad.

## Pruebas locales con Docker Compose

Seguir los pasos anteriores en la sección "Levantar el stack local" para probar la aplicación. Los servicios estarán disponibles en:

- Interfaz de votación: http://localhost:8080
- Interfaz de resultados: http://localhost:8081
