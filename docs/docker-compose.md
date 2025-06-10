# Levantar el stack completo con Docker Compose

Dentro de `app/`, ejecutar:

```bash
# 1. Build y levantar todos los servicios (sin seed)
docker compose up --build -d

# 2. Verificar estado de Redis y Postgres
docker compose ps
docker compose logs -f redis db

# 3. Probar endpoints web
curl -f http://localhost:8080/health
curl -f http://localhost:8081/health

# 4. Verificar worker
docker compose logs -f worker

# 5. (Opcional) Levantar sólo el job de seed
docker compose --profile seed up --build -d seed
docker compose logs -f seed

# 6. Bajar todo y borrar volúmenes
docker compose down --volumes
