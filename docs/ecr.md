# Repositorios ECR

Los repositorios Amazon ECR (Elastic Container Registry) se gestionan con Terraform como parte de la infraestructura del proyecto.

## Repositorios Configurados

Se crean 4 repositorios ECR, uno para cada servicio de la aplicación:

1. **voting-app-vote**
   - Almacena imágenes del servicio de votación
   - Frontend para recolección de votos

2. **voting-app-result**
   - Almacena imágenes del servicio de resultados
   - Frontend para visualización de resultados

3. **voting-app-worker**
   - Almacena imágenes del worker
   - Procesa votos y actualiza la base de datos

4. **voting-app-seed-data**
   - Almacena imágenes del servicio de seed
   - Genera datos de prueba (3000 votos)

## Configuración con Terraform

Cada repositorio se crea usando el módulo `ecr-repo`:

```hcl
module "ecr_vote" {
  source = "./modules/ecr-repo"
  name   = "voting-app-vote"
  tags   = var.tags
}
```

### Características del Repositorio

Cada repositorio ECR se configura con:

- **Image Tag Mutability**: `MUTABLE`
  - Permite sobrescribir tags existentes
  - Útil para tags como `latest`

- **Scan On Push**: `true`
  - Escaneo automático de vulnerabilidades
  - Se ejecuta cada vez que se sube una imagen

- **Tags Personalizables**
  - Se pueden agregar tags para identificar ambiente, versión, etc.
  - Se definen en la variable `tags` del módulo

## Gestión Automática

Los repositorios se crean/actualizan automáticamente cuando:

1. Se hace push a la rama `develop`
2. Se ejecuta el workflow `terraform-dev.yml`
3. Terraform aplica la configuración en AWS

## Uso en CI/CD

Los repositorios ECR se utilizan en los pipelines de CI/CD para:

1. Almacenar imágenes Docker de cada servicio
2. Versionar las imágenes con tags específicos
3. Distribuir imágenes a los ambientes de Dev/Test/Prod
