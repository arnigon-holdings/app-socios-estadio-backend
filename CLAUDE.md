# `backend/` — Reglas del agente

> Lee `README.md` (descripción general, setup, arquitectura).
> Este documento define **cómo debe comportarse un agente** al trabajar aquí.

## 1. Rol en el polyrepo

API Rails que sirve a 3 consumidores:

| Consumidor | Namespace | Auth |
|---|---|---|
| Frontend público (socios) | `/api/v1/frontend/*` | JWT (`users` table) |
| Panel admin | `/api/v1/admin/*` | Cookie JWT httpOnly (`admins` table) |
| Go face-search | Lee `users`, `face_records` directamente (no HTTP) | `DATABASE_URL` compartido |

**No es un aggregator**: face-search escala independientemente y bypassa Rails para búsquedas (decisión cerrada).

## 2. Stack y comandos

- **Ruby 3.4 + Rails 8.0** (API-only, no views)
- **DB**: PostgreSQL 15 (`pg ~> 1.5`)
- **Auth**: JWT (`jwt ~> 2.9`) para frontend; Cookie httpOnly (`ActionDispatch::Cookies`) para admin
- **AWS**: `aws-sdk-rekognition ~> 1.110` (IndexFaces + SearchFaces), `aws-sdk-s3 ~> 1.180` (presigned URLs)
- **Paginación**: `kaminari ~> 1.2`
- **Rate limiting**: `rack-attack ~> 6.7`
- **CORS**: `rack-cors ~> 2.0`
- **Seed**: `seedbank ~> 0.5`

```bash
bundle exec rails s -p 3001     # Dev server (puerto 3001)
bundle exec rails db:seed       # Seed con datos de ejemplo
bundle exec rails db:migrate    # Migraciones
bundle exec rails c              # Console
bundle exec rubocop              # Lint
bundle exec brakeman            # Security scan
```

## 3. Rutas API

### Público (socios)

```
POST   /api/v1/users              # Registro
POST   /api/v1/login              # Login JWT
DELETE /api/v1/logout             # Logout
POST   /api/v1/refresh            # Refresh JWT
GET    /api/v1/me                 # current_user
POST   /api/v1/verify-phone       # Verificación de teléfono
GET    /api/v1/teams              # Listar equipos
GET    /api/v1/liveness/:id/results  # Resultados liveness
POST   /api/v1/frontend/face-poses/validate  # Validar pose facial
POST   /api/v1/frontend/users     # Registro público (socios)
```

### Admin

```
POST   /api/v1/admin/login        # Login admin (cookie httpOnly)
DELETE /api/v1/admin/logout       # Logout
GET    /api/v1/admin/dashboard    # Stats agregadas
GET    /api/v1/admin/users        # Lista paginada
GET    /api/v1/admin/users/:id    # Detalle
PATCH  /api/v1/admin/users/:id    # Editar
DELETE /api/v1/admin/users/:id    # Eliminar
GET    /api/v1/admin/users/:id/face_records  # Face records del socio
POST   /api/v1/admin/users/:id/reindex-face  # Reindexar cara (pendiente M5)
GET    /api/v1/admin/teams        # CRUD equipos
POST   /api/v1/admin/teams
PATCH  /api/v1/admin/teams/:id
DELETE /api/v1/admin/teams/:id
GET    /api/v1/admin/point_actions      # CRUD point actions
POST   /api/v1/admin/point_actions
PATCH  /api/v1/admin/point_actions/:id
DELETE /api/v1/admin/point_actions/:id
GET    /api/v1/admin/point_transactions  # Ledger (solo lectura)
GET    /api/v1/admin/audit_logs          # Audit trail (solo lectura)
```

## 4. Modelos principales

```
User          # Socio (registrado vía frontend público)
Admin         # Admin del panel (login separado de users)
Team          # Equipo de socios
PointAction   # Acción que otorga/pierde puntos
PointTransaction  # Movimiento de puntos (creado por background jobs)
FaceRecord    # Face indexado en Rekognition (user_id FK)
AuditLog      # Log de auditoría (admin actions + system events)
```

**Relación clave**: `User` tiene muchos `FaceRecord`. Cada `FaceRecord` tiene un `rekognition_face_id`. La búsqueda en Go service usa Rekognition collection + join con `face_records.user_id`.

## 5. Services (background / core logic)

| Service | Responsabilidad |
|---|---|
| `FaceIndexer` | Indexa foto en Rekognition + crea `FaceRecord` |
| `FaceDeleter` | Elimina face de Rekognition + soft-delete `FaceRecord` |
| `S3Uploader` | Sube foto a S3 + retorna presigned URL |
| `PhotoUploader` | Valida imagen + llama S3Uploader |
| `JwtService` | Encode/decode JWT, refresh, expiry |
| `LivenessValidator` | Valida sesión liveness (pose facial) |

## 6. Variables de entorno

| Var | Requerida | Default | Notes |
|---|---|---|---|
| `DATABASE_URL` | sí | — | PostgreSQL connection string |
| `JWT_SECRET` | sí | — | Secret para firmar JWTs (min 32 chars) |
| `JWT_EXPIRY_HOURS` | no | 24 | Expiry del JWT para users |
| `FRONTEND_JWT_EXPIRY_HOURS` | no | 168 (7d) | Expiry del JWT para users |
| `ADMIN_JWT_EXPIRY_HOURS` | no | 24 | Expiry de la cookie admin |
| `AWS_REGION` | sí | `us-east-1` | Región AWS |
| `AWS_ACCESS_KEY_ID` | dev | — | IAM user (prod: IAM role) |
| `AWS_SECRET_ACCESS_KEY` | dev | — | Idem |
| `REKOGNITION_COLLECTION_ID` | no | `socios_stadium_users` | Debe matchear con face-search |
| `S3_BUCKET_NAME` | no | `perfilamiento-faces` | Bucket de faces |
| `CORS_ORIGINS` | sí | — | CSV de origins permitidos |
| `SECRET_KEY_BASE` | sí | — | Rails secrets |

## 7. Convenciones de código

- **Ruby 3.4**: keyword arguments preferidos sobre hash options.
- **Rails 8**: usar `ActiveRecord::Base` queries con scope methods.
- **Services**: una clase por archivo en `app/services/`, inyección por constructor.
- **Tests**: mínimo `bundle exec rails test`. Pendiente cobertura completa (ver CHECKLIST).
- **Sin `any` en TypeScript** — el frontend admin usa los tipos de `User`, `Team`, etc. definidos en `SPEC.md`.
- **Errors**: mapeo HTTP status → mensaje en cada controller.

## 8. Decisiones arquitectónicas cerradas

- **JWT para users, cookie httpOnly para admins** — no mezclar.
- **Rekognition como motor de face search** — no cambiar a otro proveedor.
- **Face-search bypass Rails** — decisión cerrada, no reversar.
- **Kaminari para paginación** — estándar Rails.
- **Rack-attack para rate limiting** — proteger endpoints públicos (login, registro).

## 9. Boundaries

**Hace el backend:**
- Auth (JWT users + cookie admins)
- CRUD users/teams/point_actions (admin)
- Face indexing + deletion ( Rekognition + S3)
- Liveness validation (pose facial)
- Presigned URLs para fotos
- Audit logging

**NO hace el backend:**
- Face search (lo hace Go service)
- Frontend React (panel admin)
- Frontend público (SPA React)
- Camera streaming (camera-server)
- Infra (Terraform)

## 10. Documentos hermana

- [`arnigon-holdings/app-socios-estadio-docs`](https://github.com/arnigon-holdings/app-socios-estadio-docs): SPEC, ARCHITECTURE, AGENTS, CHECKLIST, INFRASTRUCTURE, ENVIRONMENT
- [`arnigon-holdings/app-socios-estadio-face-search`](https://github.com/arnigon-holdings/app-socios-estadio-face-search): Go service que bypassea este backend para face search
- [`arnigon-holdings/app-socios-estadio-admin`](https://github.com/arnigon-holdings/app-socios-estadio-admin): panel admin que consume este backend
- [`arnigon-holdings/app-socios-estadio-frontend`](https://github.com/arnigon-holdings/app-socios-estadio-frontend): SPA React pública para socios
- [`arnigon-holdings/app-socios-estadio-infra`](https://github.com/arnigon-holdings/app-socios-estadio-infra): Terraform + deploy

## 11. Checklist pre-commit

- [ ] `bundle exec rubocop` exit 0
- [ ] `bundle exec rails test` passing
- [ ] No secrets en diff: `git grep -nE "AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}"` vacío
- [ ] Si tocaste modelos: verificar migrations + seed
- [ ] Si agregaste env vars: actualizar `.env.example`
- [ ] Si cambiaste Rekognition collection ID: verificar que face-search usa el mismo

## 12. Tier de riesgo

**External-write (medio-alto)** — modifica Rekognition, S3, PostgreSQL, y expide JWTs.

- Cambios a `FaceIndexer` / `FaceDeleter`: requieren coordinación con Go service (misma collection ID)
- Cambios a auth (JWT structure, expiry): breaking para frontend y admin
- Cambios a `users` schema: breaking para todos los consumidores
- Cambios a CORS: pueden bloquear al frontend y admin
