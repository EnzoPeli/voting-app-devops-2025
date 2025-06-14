# DevOps Voting-app 2025

## Contenidos

1. [Visión General](#visión-general)  
2. [Estructura del Repositorio](#estructura-del-repositorio)  
3. [Kanban & Flujo de Trabajo](#kanban--flujo-de-trabajo)  
4. [Infraestructura como Código (IaC)](#infraestructura-como-código-iac)  
5. [CI/CD](#cicd)  
6. [Containerización & Docker Compose](#containerización--docker-compose)  
7. [Serverless](#serverless)  
8. [Observabilidad](#observabilidad)  
9. [Próximos Pasos](#próximos-pasos)



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



## Estado inicial del tablero Kanban

![Estado inicial del Kanban](docs/initial-kanban.png)

## Infraestructura Dev

Después de aplicar Terraform en el entorno Dev, se crearon los siguientes recursos en AWS:

1. **VPC**: bloque CIDR `10.0.0.0/16` con DNS habilitado.  
2. **Subnets Públicas**: dos subnets (`10.0.1.0/24` y `10.0.2.0/24`) en distintas Availability Zones.  
3. **Internet Gateway** y tabla de rutas asociada para permitir tráfico saliente.  
4. **Security Group**: permite tráfico HTTP (puerto 80) y SSH (22) desde `0.0.0.0/0`.

![Infraestructura Dev](docs/infra-dev.png)

> **Nota**: La captura anterior muestra la VPC y sus subnets en AWS Console, confirmando que Terraform aplicó correctamente los recursos en el entorno Dev.


## Ramas principales

### main

- Código de infraestructura estable
- Listo para producción

### develop

- Integración de cambios aprobados
- Código de infraestructura en testing/dev

## Feature branches

Las feature branches se crean siempre a partir de develop.

### Nomenclatura

- Formato: `feature/infra-<descripción-corta>`
- Ejemplos:
  - `feature/infra-network-module`
  - `feature/infra-security-group`

### Flujo de trabajo

```bash
git checkout develop
git checkout -b feature/infra-<descripción>
# Hacer cambios en infra
git push origin feature/infra-<descripción>
```

### Proceso de Pull Request

1. Abrir PR feature → develop
2. Debe pasar el Terraform Plan workflow
3. Requiere revisiones de al menos un reviewer
4. Al aprobarse, se mergea a develop

## Release / Producción

### Proceso

1. Validar develop (tests, plan, deploy en Dev y Test)
2. Aprobar PR develop → main
3. Opcionalmente, añadir tag en main (ej: `v1.0-infra`)


# Validación de Dockerfiles

- **app/vote**  
  - Se construye y sirve correctamente en `localhost:8080`.  
- **app/result**  
  - Se construye y sirve correctamente en `localhost:5000`.  
- **app/seed-data**  
  - Es un job que corre y termina sin exponer HTTP.  
- **app/worker**  
  - Arranca correctamente, pero se queda en:
    ```
    Waiting for db
    Waiting for db
    …
    ```
    Esto es porque el worker **depende** de que exista un servicio de base de datos al que conectarse. Hay que levantar primero el contenedor de DB para que finalice el arranque.

**Conclusión**: Todos los Dockerfiles son válidos. La única dependencia extra es la DB para el worker.



## Pruebas locales con Docker Compose

Para levantar y probar todo el stack usar la guía en [docs/docker-compose.md](docs/docker-compose.md).