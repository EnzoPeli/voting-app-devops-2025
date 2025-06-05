# DevOps Voting-app 2025

## Estado inicial del tablero Kanban

![Estado inicial del Kanban](docs/initial-kanban.png)

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
