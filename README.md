# DevOps Voting-app 2025

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
