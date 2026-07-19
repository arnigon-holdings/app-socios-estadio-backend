# `backend/` — Rails 8 API

API JSON-only. Stack: Ruby 3.4 + Rails 8.0 + PostgreSQL 16 + Redis 7 + JWT + Rack::Attack + Sidekiq-ready (no instalado aún).

## Quickstart

```bash
# Solo DB + Redis (sin app)
docker compose up -d postgres redis

# Instalar gems
docker compose run --rm app bundle install

# DB
docker compose run --rm app bundle exec rails db:migrate db:seed

# Levantar todo (incluye face-search Go service)
docker compose up -d
```

API en `http://localhost:3000`, healthcheck `GET /up`.

## Estructura

```
backend/
├── app/
│   ├── controllers/api/
│   │   ├── v1/
│   │   │   ├── frontend/        ← registro público (socios)
│   │   │   └── admin/           ← panel admin
│   │   └── auth_controller.rb   ← login/refresh JWT
│   ├── models/
│   │   ├── user.rb              ← socio
│   │   ├── face_record.rb       ← cara indexada (rekognition_face_id + s3_key)
│   │   ├── admin.rb
│   │   └── ...
│   └── services/
│       ├── jwt_service.rb
│       ├── s3_uploader.rb       ← base64 → S3 (SSE-S3 + content-type check)
│       ├── face_indexer.rb      ← S3 + IndexFaces + face_records (transaccional)
│       └── liveness_validator.rb ← Rekognition GetFaceLivenessSessionResults SDK
├── db/
│   ├── migrate/
│   │   └── 20260626090001_add_face_records_and_indexed_at.rb
│   ├── schema.rb
│   └── seeds.rb                 ← 1 admin + 33 teams + 5 point_actions + 50 fake users
├── config/
│   ├── application.rb
│   ├── database.yml
│   ├── routes.rb
│   └── initializers/
│       ├── aws.rb               ← setea AWS region
│       └── rack_attack.rb
├── docker-compose.yml           ← servicios: postgres, redis, app, face-search
└── .env.example, .env.development    ← tracked, sin secretos
    .env.aws                     ← (gitignored) AWS IAM keys dev
```

## Endpoints principales

### Públicos

- `POST /api/v1/frontend/users` — registro de socio (RUT, phone, password, photo base64, audit_images, consents).
- `GET /api/v1/teams` — equipos activos (para selector).
- `GET /api/v1/liveness/:session_id/results` — resultados de liveness (llama `GetFaceLivenessSessionResults` via SDK de Rekognition, no via API Gateway). Retorna `{ sessionId, confidence, status, referenceImage }`.

### Auth (admin)

- `POST /api/v1/admin/login` → JWT cookie httpOnly.
- `DELETE /api/v1/admin/logout`
- `GET /api/v1/admin/dashboard` → stats.
- `GET /api/v1/admin/users` (paginated, RUT filter)
- `GET /api/v1/admin/users/:id`
- `PATCH /api/v1/admin/users/:id`
- `DELETE /api/v1/admin/users/:id`
- `GET /api/v1/admin/users/:id/face_records`
- `POST /api/v1/admin/users/:id/reindex-face` *(pendiente)*
- `GET /api/v1/admin/teams`, `POST`, `PATCH`, `DELETE`
- `GET /api/v1/admin/point_actions`, `POST`, `PATCH`, `DELETE`
- `GET /api/v1/admin/point_transactions`
- `GET /api/v1/admin/audit_logs`

### Flow M5 (registro → index → búsqueda)

1. `POST /api/v1/frontend/users` → **`LivenessValidator.validate(session_id)`** re-verifica contra Rekognition SDK. Si falla, 422. Luego crea `User` con `photo_url` (local) y dispara `FaceIndexer` async-style (sync, non-blocking).
2. `FaceIndexer.index` sube foto a S3 (`users/<id>/reference/<uuid>.<ext>`), llama `Rekognition.IndexFaces`, crea `face_records` y setea `users.indexed_at`.
3. Admin → `/face-search` (admin panel) → POST a Go service `/search-face` → Rekognition `SearchFacesByImage` → match con `user_id` → JOIN en DB → response con `rut`, `phone`, `confidence`, `photo_url` (presigned S3 1h).

## Comandos

```bash
# Tests
docker compose run --rm app bundle exec rails test

# Lint (RuboCop)
docker compose run --rm app bundle exec rubocop

# Consola
docker compose run --rm app bundle exec rails console

# Migración
docker compose run --rm app bundle exec rails db:migrate

# Seed (idempotente: solo crea si no existe)
docker compose run --rm app bundle exec rails db:seed

# Reset total DB (BORRA DATOS, conserva schema)
docker compose run --rm app bundle exec rails db:reset

# Logs
docker compose logs -f app
docker compose logs -f face-search
```

## Env vars

Toda la configuración de runtime vive en variables de entorno. **No hay secretos hardcodeados en código**.

### Archivos de configuración

| Archivo | Estado | Propósito |
|---|---|---|
| `backend/.env.example` | tracked | Template con todas las variables documentadas (placeholders) |
| `backend/.env.development` | tracked (sin secretos reales) | Defaults de dev — funciona out-of-the-box con `docker compose up` |
| `backend/.env.aws` | gitignored | Credenciales AWS IAM (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`). Solo dev. En prod usar IAM role. |
| `backend/.env.production` | gitignored | Override de prod — seteado por Secret Manager / Cloud Run |

### Cómo cargar variables

- **Docker Compose (dev)**: lee `backend/.env.development` y `backend/.env.aws` automáticamente. Cualquier variable en `environment:` del compose usa `${VAR}` con fallback `${VAR:-default}`.
- **Producción (Cloud Run)**: las variables se montan desde GCP Secret Manager (`--set-secrets`) o env vars del servicio. Nunca en el código.
- **Tests**: `RAILS_ENV=test bundle exec rails db:test:prepare` carga solo lo mínimo (DB `app_perfil_test`).

### Tabla de variables

#### Rails core

| Var | Requerida | Default dev | Para qué sirve |
|---|---|---|---|
| `RAILS_ENV` | sí | `development` | Entorno Rails (development/test/production) |
| `RAILS_LOG_LEVEL` | no | `info` | Nivel de log (`debug`, `info`, `warn`, `error`) |
| `RAILS_SERVE_STATIC_FILES` | no | — | Si truthy, Rails sirve `/public` (no usar, prefer Nginx/CDN) |
| `SECRET_KEY_BASE` | **sí (prod)** | — | Firma de cookies/secrets de Rails. Generar con `rails secret`. ≥ 64 chars. **PROD: raise si falta**. |
| `JWT_SECRET_KEY` | **sí** | dev default | HMAC para firmar JWT (admin + socio). ≥ 32 chars. **PROD: raise si falta**. |
| `PORT` | no | `3000` | Puerto del server Rails |

#### Postgres

| Var | Requerida | Default dev | Para qué sirve |
|---|---|---|---|
| `DATABASE_URL` | sí (prod) | — | URL completa de Postgres. Tiene prioridad sobre DB_HOST/USER/PASSWORD. |
| `DB_HOST` | sí (dev) | `localhost` | Host de Postgres |
| `DB_PORT` | no | `5432` | Puerto |
| `DB_USER` | no | `app_perfil` | Usuario de la DB |
| `DB_PASSWORD` | **sí (prod)** | dev default | Password de la DB. **PROD: raise si falta**. |
| `DB_POOL` | no | `5` | Pool de conexiones ActiveRecord |

#### Redis

| Var | Requerida | Default dev | Para qué sirve |
|---|---|---|---|
| `REDIS_URL` | sí | — | Conexión Redis (rate-limit Rack::Attack, futuro Sidekiq) |

#### CORS

| Var | Requerida | Default dev | Para qué sirve |
|---|---|---|---|
| `CORS_ORIGINS` | sí | `localhost:5173,5174` | CSV de origins permitidos para CORS. Sin esto, default a localhost dev. |

#### AWS — credenciales + región

| Var | Requerida | Default dev | Para qué sirve |
|---|---|---|---|
| `AWS_REGION` | sí | `us-east-1` | Región AWS (Rekognition + S3) |
| `AWS_ACCESS_KEY_ID` | solo dev | — | IAM user con permisos S3 + Rekognition. **PROD: usar IAM role, no env var**. |
| `AWS_SECRET_ACCESS_KEY` | solo dev | — | Idem. **PROD: IAM role**. |
| `AWS_PROFILE` | opcional | — | Alternativa: shared AWS profile. Si está set, tiene prioridad sobre ACCESS_KEY. |

#### AWS — S3

| Var | Requerida | Default dev | Para qué sirve |
|---|---|---|---|
| `AWS_S3_BUCKET_NAME` | sí | `perfilamiento-faces` | Bucket donde se suben las fotos de referencia + audit. |
| `ACTIVE_STORAGE_SERVICE` | no | `local` | `local` (dev: filesystem) o `r2` (prod: Cloudflare R2). |

#### AWS — Rekognition

| Var | Requerida | Default dev | Para qué sirve |
|---|---|---|---|
| `REKOGNITION_COLLECTION_ID` | sí | `socios_stadium_users` | ID de la colección de Rekognition donde se indexan las caras. |

#### Seed admin (solo dev)

Estas credenciales se crean con `rails db:seed`. **Nunca setear en producción**.

| Var | Default dev | Para qué sirve |
|---|---|---|
| `SEED_ADMIN_EMAIL` | `admin@appperfil.cl` | Email del superadmin seed |
| `SEED_ADMIN_PASSWORD` | `Admin123!` | Password del superadmin seed |
| `SEED_OPERATOR_EMAIL` | `operador@appperfil.cl` | Email del operador seed |
| `SEED_OPERATOR_PASSWORD` | `Operador123!` | Password del operador seed |
| `SEED_SUPPORT_EMAIL` | `soporte@appperfil.cl` | Email del soporte seed |
| `SEED_SUPPORT_PASSWORD` | `Soporte123!` | Password del soporte seed |

### Dónde cambiar cada clave (resumen rápido)

- **Cambiar passwords admin**: setear `SEED_ADMIN_PASSWORD`, `SEED_OPERATOR_PASSWORD`, `SEED_SUPPORT_PASSWORD` en `.env.development` (dev) o Secret Manager (prod). Después correr `rails db:seed` para recrear.
- **Cambiar password DB local**: editar `POSTGRES_PASSWORD` en `.env.development` y `docker-compose.yml` (línea `POSTGRES_PASSWORD:`). El service de Postgres debe reiniciarse.
- **Cambiar bucket S3**: `AWS_S3_BUCKET_NAME` en `.env.development` (dev) o Secret Manager (prod). Datos viejos quedan en el bucket anterior.
- **Cambiar colección Rekognition**: `REKOGNITION_COLLECTION_ID`. **Cuidado**: cambiar esto invalida todos los face_ids existentes (no hay migración).
- **Cambiar CORS origins**: `CORS_ORIGINS` (CSV). Ej: `CORS_ORIGINS=https://app.x.cl,https://admin.x.cl`.
- **Rotar JWT secret**: cambiar `JWT_SECRET_KEY`. **Invalida todas las sesiones activas** — los usuarios deben re-loguearse.
- **Rotar AWS keys**: en IAM console crear nuevas, actualizar `backend/.env.aws` (dev) o Service Account key (prod). Borrar viejas.

## Gotchas

- **`bundle install` corre en cada `docker compose up -d`** porque hay un `bundle` named volume y el comando es `bundle install --quiet && bundle exec rails server`. Primer boot es lento (~1 min).
- **Sin `db:reset` antes de `db:seed`**: siembra agrega duplicados (idempotencia parcial). Usar `db:reset` para clean state.
- **El comando del `app` service en compose** corre `bundle install --quiet` siempre. Si cambias `Gemfile`, no necesitás rebuild — el volume `bundle` persiste.
- **`face_records` existe desde M5**: si hacés `db:reset`, los faces en Rekognition quedan huérfanos (pointing a user_ids que ya no existen). `face-search` los ignora silenciosamente.
- **El secret `JWT_SECRET_KEY` debe tener ≥32 chars** (validación al boot).
- **Tests usan DB `app_perfil_test`** (separada de dev). El compose no la crea automáticamente; tenés que correr `RAILS_ENV=test bundle exec rails db:test:prepare`.
- **Puerto del backend: 3000**. El docker compose mapea `3000:3000`. Si el puerto 3000 está ocupado, liberarlo antes de levantar. El frontend tiene `VITE_API_BASE_URL` en su `.env` — debe coincidir con el puerto real del backend (cambiar a `3001` si se remapea el puerto en el compose).
- **`LivenessValidator` usa SDK de Rekognition (no API Gateway)**: evita CORS en el browser. El frontend llama `/api/v1/liveness/:sessionId/results` que pasa por el proxy de Vite en dev. En prod, el frontend llama directo al backend Rails con CORS configurado.

## Decisiones arquitectónicas

- **Controllers delgados**, lógica de negocio en `app/services/` y modelos.
- **`FaceIndexer` no raise**: errores logueados pero registration sigue OK. `users.indexed_at` queda NULL → admin puede reindexar después.
- **JWT en cookie httpOnly** (no Authorization header) para admin; frontend usa `credentials: 'include'`.
- **`S3Uploader` valida formato y tamaño antes** de subir (max 5MB, JPEG/PNG).
- **`Rekognition.QualityFilter: AUTO`** descarta fotos borrosas automáticamente (warning logged, no bloquea).
- **Sin Sidekiq todavía**: `FaceIndexer` corre inline en el controller (sync). Aceptable para volúmenes actuales (~10s por registro). Migrar a ActiveJob + Sidekiq si crece.

## Próximos pasos (ver [CHECKLIST.md](https://github.com/arnigon-holdings/app-socios-estadio-docs/blob/main/CHECKLIST.md))

- Tests unitarios `FaceIndexer` + `S3Uploader`.
- Retry con backoff para `IndexFaces`.
- Endpoint admin `POST /api/v1/admin/users/:id/reindex-face`.
- ActiveJob + Sidekiq para mover `FaceIndexer` off-request.
