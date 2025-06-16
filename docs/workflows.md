# Workflows de CI/CD

Este documento describe los workflows de GitHub Actions utilizados en el proyecto.

## Pipeline de Pruebas (`docker-test.yml`)

Este workflow se encarga de ejecutar las pruebas de integración usando Postman/Newman.

### Flujo del Pipeline

1. **Checkout del código**
   - Usa `actions/checkout@v4`

2. **Preparación de Newman**
   - Instala Node.js 18
   - Instala Newman globalmente (`npm install -g newman`)

3. **Preparación y arranque de servicios**
   ```yaml
   - name: Prepare and start services
     run: |
       cd app
       cp .env.example .env
       chmod +x healthchecks/*.sh  # Dar permisos a scripts de healthcheck
       docker compose up -d --build
   ```

4. **Espera de healthchecks**
   - Espera hasta 2.5 minutos (30 intentos × 5 segundos)
   - Verifica que todos los servicios estén healthy
   ```yaml
   for i in {1..30}; do
     if docker compose ps | grep -q unhealthy; then
       echo "Waiting for healthy services... (attempt $i/30)"
       sleep 5
     else
       echo "All services are healthy"
       break
     fi
   done
   ```

5. **Ejecución de pruebas Postman**
   ```yaml
   - name: Run Postman integration tests
     working-directory: .  # Ejecutar desde raíz del proyecto
     run: |
       newman run tests/Voting-app-Integration-Tests.postman_collection.json \
         --environment tests/Local.postman_environment.json \
         --reporters cli,json \
         --reporter-json-export newman-results.json
   ```

6. **Recolección de resultados**
   - Guarda resultados de Newman como artefacto
   - Guarda logs de Docker Compose
   - Limpia recursos (docker compose down)

## Pipeline de Infraestructura (`terraform-dev.yml`)

Este workflow gestiona la infraestructura AWS usando Terraform. Se ejecuta automáticamente cuando hay cambios en la rama `develop`.

### Flujo del Pipeline

1. **Checkout del código**
   - Usa `actions/checkout@v4` para clonar el repositorio
   - Obtiene la última versión de la rama `develop`

2. **Configuración de AWS**
   ```yaml
   - name: Configure AWS Credentials
     uses: aws-actions/configure-aws-credentials@v1
     with:
       aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
       aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
       aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
       aws-region: ${{ secrets.AWS_DEFAULT_REGION }}
   ```
   - Configura credenciales de AWS usando secretos del repositorio
   - Permite a Terraform interactuar con servicios AWS (ECR, S3, etc.)

3. **Configuración de Terraform**
   ```yaml
   - name: Set up Terraform
     uses: hashicorp/setup-terraform@v3
     with:
       terraform_wrapper: false
   ```
   - Instala la versión correcta de Terraform
   - Deshabilita wrapper para mejor integración con GitHub Actions

4. **Inicialización y Plan**
   ```yaml
   - name: Initialize Terraform
     working-directory: infra
     run: terraform init

   - name: Create Terraform Plan
     working-directory: infra
     run: terraform plan -out=tfplan
   ```
   - Inicializa backend S3 para estado remoto
   - Genera plan detallando cambios a realizar
   - Guarda plan como artefacto para revisión

5. **Aplicación de Cambios**
   ```yaml
   - name: Apply Terraform Plan
     working-directory: infra
     run: terraform apply -auto-approve tfplan
   ```
   - Aplica el plan sin intervención manual (`-auto-approve`)
   - Crea/actualiza recursos en AWS:
     - Repositorios ECR para cada servicio
     - Configuración de escaneo y tags
     - Otros recursos de infraestructura

### Infraestructura Gestionada

1. **Repositorios ECR**
   - `voting-app-vote`: Frontend de votación
   - `voting-app-result`: Frontend de resultados
   - `voting-app-worker`: Procesador de votos
   - `voting-app-seed-data`: Generador de datos de prueba

2. **Estado Remoto**
   - Bucket S3: `voting-app-terraform-state-177816`
   - Tabla DynamoDB: `terraform-locks`
   - Región: `us-east-1`

3. **Recursos de Red**
   - VPC y subnets para servicios
   - Grupos de seguridad
   - Otras configuraciones de red

## Pipeline de Desarrollo (`docker-dev.yml`)

Este workflow realiza análisis estático y construcción de imágenes Docker para cada servicio. Se ejecuta automáticamente en push a `develop`.

### Análisis Estático

Se ejecuta en paralelo para cada servicio usando una matriz de configuración:

```yaml
strategy:
  matrix:
    include:
      - service: vote
        path: app/vote
        type: python
      - service: result
        path: app/result
        type: node
      - service: seed-data
        path: app/seed-data
        type: python
      - service: worker
        path: app/worker
        type: csharp
```

#### Análisis por Lenguaje

1. **Python (vote, seed-data)**
   ```yaml
   pip install --user -r requirements-dev.txt
   flake8 . --format='%(path)s:%(row)d:%(col)d: %(code)s %(text)s' \
     --output-file flake8-report.txt
   ```
   - Usa Flake8 para análisis de código
   - Genera reporte detallado con ubicación de errores

2. **Node.js (result)**
   ```yaml
   npm install
   npm install eslint@8.56.0
   npx eslint . --format unix --output-file eslint-report.txt
   ```
   - Usa ESLint para análisis de código
   - Verifica estándares de JavaScript/Node.js

3. **C# (worker)**
   ```yaml
   dotnet tool install --global dotnet-format
   dotnet restore
   dotnet format . --verify-no-changes --report dotnet-report.txt
   ```
   - Usa dotnet-format para verificar estilo
   - Comprueba formato y convenciones de C#

### Construcción de Imágenes

1. **Login a ECR**
   ```yaml
   - name: Configure AWS credentials
     uses: aws-actions/configure-aws-credentials@v1
   - name: Login to Amazon ECR
     uses: aws-actions/amazon-ecr-login@v1
   ```
   - Configura credenciales AWS
   - Autentica con Amazon ECR

2. **Build y Push**
   ```yaml
   - name: Build and push ${{ matrix.service }}
     working-directory: ${{ matrix.path }}
     run: |
       docker build -t $ECR_REGISTRY/${{ matrix.service }}:${{ github.sha }} .
       docker push $ECR_REGISTRY/${{ matrix.service }}:${{ github.sha }}
   ```
   - Construye imagen Docker para cada servicio
   - Tagea con SHA del commit
   - Sube a repositorio ECR

### Artefactos y Reportes

- Guarda reportes de análisis estático como artefactos
- Permite revisar problemas de código detectados
- Mantiene historial de builds y análisis

## Notas Importantes

- Los scripts de healthcheck necesitan permisos de ejecución (`chmod +x`)
- El tiempo de espera para servicios es configurable (actualmente 2.5 min)
- Las pruebas de integración usan la colección Postman en `/tests`
- El pipeline de Terraform se ejecuta automáticamente en push a `develop`
