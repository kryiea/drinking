# Yinzhi Backend

## Local setup

```bash
./scripts/setup-backend.sh
uvicorn app.main:app --app-dir backend --reload
```

## Current state
- Uses SQLAlchemy persistence with startup schema creation and seed data.
- Defaults to local SQLite for no-infra development, and can switch to PostgreSQL via `YINZHI_DATABASE_URL`.
- Keeps production-shaped route groups and service seams.
- Ready to layer migrations, Redis, and object storage adapters on top of the current persistence boundary.
- Local infra can be started with `./scripts/start-infra.sh`.
