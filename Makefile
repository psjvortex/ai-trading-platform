up:
	docker compose up -d --build

down:
	docker compose down -v

logs:
	docker compose logs -f --tail=100

test:
	docker compose run --rm api pytest -q && docker compose run --rm web sh -lc 'pnpm install && pnpm test'

fmt:
	( cd backend && black . && ruff check --fix . ) && ( cd web && pnpm format )

lint:
	( cd backend && ruff check . && black --check . ) && ( cd web && pnpm lint )

train-rl:
	@echo "stub"

backfill:
	@echo "stub"
