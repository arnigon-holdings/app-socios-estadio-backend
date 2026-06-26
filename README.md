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
│       └── face_indexer.rb      ← S3 + IndexFaces + face_records (transaccional)
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

1. `POST /api/v1/frontend/users` → crea `User` con `photo_url` (local) y dispara `FaceIndexer` async-style (sync, non-blocking).
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

| Var | Source | Descripción |
|---|---|---|
| `DATABASE_URL` | compose | Postgres |
| `REDIS_URL` | compose | Redis (rate-limit, futuro Sidekiq) |
| `RAILS_ENV` | compose | `development` |
| `JWT_SECRET_KEY` | compose | HMAC para JWTs |
| `CORS_ORIGINS` | compose | Origins permitidos (separados por coma) |
| `AWS_REGION` | `.env.aws` | us-east-1 |
| `AWS_ACCESS_KEY_ID` | `.env.aws` | (gitignored) |
| `AWS_SECRET_ACCESS_KEY` | `.env.aws` | (gitignored) |
| `AWS_S3_BUCKET_NAME` | compose | `perfilamiento-faces` |
| `REKOGNITION_COLLECTION_ID` | compose | `socios_stadium_users` |

## Gotchas

- **`bundle install` corre en cada `docker compose up -d`** porque hay un `bundle` named volume y el comando es `bundle install --quiet && bundle exec rails server`. Primer boot es lento (~1 min).
- **Sin `db:reset` antes de `db:seed`**: siembra agrega duplicados (idempotencia parcial). Usar `db:reset` para clean state.
- **El comando del `app` service en compose** corre `bundle install --quiet` siempre. Si cambias `Gemfile`, no necesitás rebuild — el volume `bundle` persiste.
- **`face_records` existe desde M5**: si haces `db:reset`, los faces en Rekognition quedan huérfanos (pointing a user_ids que ya no existen). `face-search` los ignora silenciosamente.
- **El secret `JWT_SECRET_KEY` debe tener ≥32 chars** (validación al boot).
- **Tests usan DB `app_perfil_test`** (separada de dev). El compose no la crea automáticamente; tenés que correr `RAILS_ENV=test bundle exec rails db:test:prepare`.

## Decisiones arquitectónicas

- **Controllers delgados**, lógica de negocio en `app/services/` y modelos.
- **`FaceIndexer` no raise**: errores logueados pero registration sigue OK. `users.indexed_at` queda NULL → admin puede reindexar después.
- **JWT en cookie httpOnly** (no Authorization header) para admin; frontend usa `credentials: 'include'`.
- **`S3Uploader` valida formato y tamaño antes** de subir (max 5MB, JPEG/PNG).
- **`Rekognition.QualityFilter: AUTO`** descarta fotos borrosas automáticamente (warning logged, no bloquea).
- **Sin Sidekiq todavía**: `FaceIndexer` corre inline en el controller (sync). Aceptable para volúmenes actuales (~10s por registro). Migrar a ActiveJob + Sidekiq si crece.

## Próximos pasos (ver CHECKLIST.md)

- Tests unitarios `FaceIndexer` + `S3Uploader`.
- Retry con backoff para `IndexFaces`.
- Endpoint admin `POST /api/v1/admin/users/:id/reindex-face`.
- ActiveJob + Sidekiq para mover `FaceIndexer` off-request.
