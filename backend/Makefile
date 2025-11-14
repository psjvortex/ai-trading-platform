dev:
	python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

test:
	pytest -q

lint:
	ruff check . && black --check .

fmt:
	black . && ruff check --fix .

migrate:
	alembic upgrade head

seed:
	python -m app.scripts.seed_symbols

migrate-autogen:
	alembic revision --autogenerate -m "auto"
