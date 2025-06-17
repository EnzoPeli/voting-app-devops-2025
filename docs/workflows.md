# Workflows de CI/CD

Este documento describe los workflows de GitHub Actions para CI/CD del proyecto voting-app.

## Pipeline de Desarrollo (`terraform-dev.yml`)

Este workflow gestiona la infraestructura AWS con Terraform.

### Características

1. **Credenciales AWS**
   - Usa credenciales temporales del lab
   - Configura región por defecto

2. **Recursos Gestionados**
   - Repositorios ECR para cada servicio
   - Networking (VPC, subnets, etc.)
   - Backend S3 para estado

### Terraform Init & Apply

```yaml
steps:
  - name: Setup Terraform
    run: |
      terraform init \
        -backend-config="bucket=voting-app-terraform-state" \
        -backend-config="key=voting-app/dev.tfstate"

  - name: Terraform Plan & Apply
    run: |
      terraform plan -var-file=dev.tfvars
      terraform apply -auto-approve -var-file=dev.tfvars
```

## Pipeline de Test (`docker-test.yml`)

Este workflow ejecuta pruebas de integración con Postman/Newman.

### Características

1. **Servicios Docker**
   - Levanta todos los servicios con `docker compose`
   - Espera a que estén healthy

2. **Pruebas de Integración**
   - Usa colección Postman
   - Ejecuta con Newman
   - Valida endpoints y flujos

### Ejecución de Tests

```yaml
steps:
  - name: Run integration tests
    run: |
      newman run tests/Voting-app-Integration-Tests.postman_collection.json \
        --environment tests/Local.postman_environment.json
```

## Pipeline de Desarrollo (`docker-dev.yml`)

Este workflow realiza análisis estático y build de imágenes.

### Características

1. **Análisis Estático**
   - Python: flake8
   - Node.js: eslint
   - C#: dotnet format

2. **Build & Push**
   - Construye imágenes Docker
   - Push a ECR con tag `:latest`

### Build y Push

```yaml
steps:
  - name: Build & push image
    run: |
      docker build -t $ECR/voting-app-service:latest .
      docker push $ECR/voting-app-service:latest
```

## Pipeline de Producción (`docker-prod.yml`)

Este workflow gestiona el build y deploy a producción. Se ejecuta automáticamente en push a `main` o cuando se crean tags con formato `v*.*.*`.

### Build y Push

```yaml
env:
  TF_VAR_file: infra/prod.tfvars

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_DEFAULT_REGION }}

      - name: Build & push vote image
        run: |
          docker build -t $ECR/voting-app-vote:prod app/vote
          docker push $ECR/voting-app-vote:prod
```

### Deploy a Producción

```yaml
deploy:
  needs: build
  environment: production
  steps:
    - name: Setup Terraform
      run: |
        terraform init -backend-config="key=voting-app/prod.tfstate"
        terraform plan -var-file=prod.tfvars
        terraform apply -auto-approve -var-file=prod.tfvars
```

### Protección del Ambiente de Producción

Para garantizar deploys seguros a producción:

1. Ve a **Settings → Environments** del repositorio
2. Crea un nuevo Environment llamado `production`
3. En **Deployment protection rules**:
   - Habilita **Required reviewers**
   - Selecciona los revisores autorizados

Esto establece un quality gate:
- El job `build` corre automáticamente en push a `main`
- El job `deploy` requiere aprobación manual de un revisor
- Queda registro de quién aprobó cada deploy

## Notas Importantes

- Los scripts de healthcheck necesitan permisos de ejecución (`chmod +x`)
- Los archivos de entorno deben estar presentes (`.env` o `.env.example`)
- Las credenciales AWS deben configurarse como secretos en GitHub
