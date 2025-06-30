# Workflows de CI/CD

Este documento describe los workflows de GitHub Actions para CI/CD del proyecto voting-app. La estructura de workflows está diseñada para soportar múltiples ambientes (dev, test, prod) con pipelines unificados para cada ambiente.

## Estructura de Workflows

Los workflows están organizados por ambiente, con un pipeline completo para cada uno:

1. **Pipeline de Desarrollo**: [ci-dev.yml]
   - Análisis estático de código
   - Infraestructura con Terraform
   - Construcción y publicación de imágenes Docker
   - Despliegue en Kubernetes (namespace `dev`)

2. **Pipeline de Test**: [ci-test.yml]
   - Pruebas de integración
   - Infraestructura con Terraform
   - Construcción y publicación de imágenes Docker
   - Despliegue en Kubernetes (namespace `test`)

3. **Pipeline de Producción**: [ci-prod.yml]
   - Infraestructura con Terraform
   - Construcción y publicación de imágenes Docker
   - Despliegue en Kubernetes (namespace `prod`)
   - Protección adicional con entorno `production`

## Pipelines por Ambiente

### 1. Pipeline de Desarrollo ([ci-dev.yml])

Este workflow integra análisis estático, infraestructura y despliegue para el ambiente de desarrollo.

**Disparador**: Push a la rama `develop`

**Jobs**:

1. **static-analysis**: Análisis estático de código
   - Python (vote, seed-data): flake8
   - Node.js (result): eslint
   - C# (worker): dotnet format
   - Genera reportes y sube artefactos

2. **terraform**: Gestión de infraestructura
   - Configura credenciales AWS
   - Setup Terraform
   - Terraform init, plan y apply con `dev.tfvars`

3. **build**: Construcción y publicación de imágenes Docker
   - Login en ECR
   - Build y push de imágenes con tag `:dev`

4. **kubernetes**: Despliegue en Kubernetes
   - Configura kubectl para EKS
   - Crea namespace `dev` si no existe
   - Aplica manifiestos con `NAMESPACE=dev`
   - Verifica readiness de pods

### 2. Pipeline de Test ([ci-test.yml])

Este workflow integra pruebas de integración, infraestructura y despliegue para el ambiente de test.

**Disparador**: Push a la rama `test`

**Jobs**:

1. **integration-tests**: Pruebas de integración
   - Levanta servicios con Docker Compose
   - Ejecuta pruebas con Postman/Newman
   - Valida endpoints y flujos

2. **terraform**: Gestión de infraestructura
   - Configura credenciales AWS
   - Setup Terraform
   - Terraform init, plan y apply con [test.tfvars](infra/test.tfvars)

3. **build**: Construcción y publicación de imágenes Docker
   - Login en ECR
   - Build y push de imágenes con tag `:test`

4. **kubernetes**: Despliegue en Kubernetes
   - Configura kubectl para EKS
   - Crea namespace `test` si no existe
   - Aplica manifiestos con `NAMESPACE=test`
   - Verifica readiness de pods

### 3. Pipeline de Producción ([ci-prod.yml])

Este workflow integra infraestructura y despliegue para el ambiente de producción con protecciones adicionales.

**Disparador**: Push a la rama `main` o tags con formato `v*.*.*`

**Jobs**:

1. **terraform**: Gestión de infraestructura
   - Configura credenciales AWS
   - Setup Terraform
   - Terraform init, plan y apply con [prod.tfvars](infra/prod.tfvars)
   - Usa el entorno `production` para protección adicional

2. **build**: Construcción y publicación de imágenes Docker
   - Login en ECR
   - Build y push de imágenes con tag `:prod`
   - Usa el entorno `production` para protección adicional

3. **kubernetes**: Despliegue en Kubernetes
   - Configura kubectl para EKS
   - Crea namespace `prod` si no existe
   - Aplica manifiestos con `NAMESPACE=prod`
   - Verifica readiness de pods
   - Usa el entorno `production` para protección adicional

## Estrategia de Namespaces en Kubernetes

Los workflows utilizan namespaces de Kubernetes para aislar los ambientes:

- Namespace `dev`: Ambiente de desarrollo
- Namespace `test`: Ambiente de pruebas
- Namespace `prod`: Ambiente de producción

Cada workflow se encarga de crear su respectivo namespace y desplegar los manifiestos en él, utilizando la variable de entorno `NAMESPACE` para parametrizar los despliegues.


## Terraform Workspaces en los Pipelines

Los workflows de CI/CD utilizan Terraform Workspaces para separar los estados y recursos por ambiente. Cada pipeline selecciona automáticamente el workspace correspondiente antes de aplicar Terraform:

```yaml
- name: Seleccionar workspace de Terraform
  working-directory: infra
  run: terraform workspace select dev || terraform workspace new dev
```

Este patrón se repite en todos los pipelines (dev, test, prod) y en el workflow de destroy, cambiando el nombre del workspace según corresponda.

> **Nota**: Para más información sobre Terraform Workspaces y su uso en el proyecto, consulta la sección correspondiente en el [README principal](../README.md#terraform-workspaces).

## Notas Importantes

- Los workflows usan variables de entorno y secretos de GitHub para configurar las credenciales de AWS y otros parámetros.
- Cada ambiente tiene su propio archivo de variables de Terraform (dev.tfvars, test.tfvars, prod.tfvars).
- Los namespaces de Kubernetes se crean automáticamente durante el despliegue si no existen.
- Los workspaces de Terraform deben crearse manualmente si no existen cuando se trabaja fuera de los pipelines de CI/CD.
- Los workflows utilizan `aws-actions/configure-aws-credentials@v2` para autenticación AWS