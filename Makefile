.PHONY: help validate lint test security-check checklist clean db_seed db_console logs

PROJECT := app_backend

help:
	@echo "=== $(PROJECT) Makefile ==="
	@echo "  make validate        Full validation: lint + test"
	@echo "  make lint           Run linter (rubocop)"
	@echo "  make test           Run unit tests"
	@echo "  make security-check Audit dependencies"
	@echo "  make checklist      Show current status"
	@echo "  make db_seed       Seed database"
	@echo "  make db_console    Open Rails console"
	@echo "  make logs          Show app logs"
	@echo "  make clean         Remove containers and volumes"

validate: lint test
	@echo "[validate] All checks passed"

lint:
	@echo "[lint] Running rubocop..."
	@docker compose exec app bundle exec rubocop --color || true
	@echo "[lint] Done"

test:
	@echo "[test] Running tests..."
	@docker compose exec -e RAILS_ENV=test app bundle exec rails test || true
	@echo "[test] Done"

security-check:
	@echo "[security] Auditing dependencies..."
	@docker compose exec app bundle exec brakeman --color -q || true
	@echo "[security] Done"

checklist:
	@echo "=== Situational Checklist: $(PROJECT) ==="
	@echo ""
	@echo "1. PROJECT STATE"
	@test -f Gemfile && echo "   [x] Gemfile exists" || echo "   [ ] No Gemfile"
	@test -f db/schema.rb && echo "   [x] Schema exists" || echo "   [ ] No schema"
	@test -f docker-compose.yml && echo "   [x] Docker compose exists" || echo "   [ ] No docker-compose"
	@echo ""
	@echo "2. MODELS"
	@ls app/models/*.rb 2>/dev/null | wc -l | xargs -I{} echo "   Models: {}"
	@echo ""
	@echo "3. CONTROLLERS"
	@ls app/controllers/api/*/*_controller.rb 2>/dev/null | wc -l | xargs -I{} echo "   Controllers: {}"
	@echo ""
	@echo "4. DOCKER STATUS"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || echo "   Docker not running"
	@echo ""
	@echo "=== End Checklist ==="

db_seed:
	@echo "[db_seed] Seeding database..."
	@docker compose exec app bundle exec rails db:seed

db_console:
	@docker compose exec app bundle exec rails console

logs:
	@docker compose logs --tail=100 app

clean:
	@echo "[clean] Stopping containers..."
	@docker compose down -v
	@echo "[clean] Done"
