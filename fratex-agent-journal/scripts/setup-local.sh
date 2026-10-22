#!/usr/bin/env bash
# Prépare un environnement local complet pour Fratex Agent (Postgres, dépendances, migrations, données de démo).
# Utilisation : bash setup-local.sh /chemin/vers/fratex-agent
set -euo pipefail
REPO="${1:-/home/user/endsi3g/fratex-agent}"
JOURNAL="$(cd "$(dirname "$0")" && pwd)"
PGBIN=/usr/lib/postgresql/16/bin
if ! pg_isready -h localhost >/dev/null 2>&1; then
	mkdir -p /tmp/pgdata && chown postgres:postgres /tmp/pgdata
	[ -f /tmp/pgdata/PG_VERSION ] || su postgres -c "$PGBIN/initdb -D /tmp/pgdata -A trust" >/dev/null
	rm -f /tmp/pgdata/postmaster.pid
	su postgres -c "$PGBIN/pg_ctl -D /tmp/pgdata -l /tmp/pg.log -o '-p 5432' start"
	sleep 3
fi
psql -U postgres -h localhost -tc "select 1 from pg_database where datname='crm'" | grep -q 1 || psql -U postgres -h localhost -c "create database crm;"
psql -U postgres -h localhost -tc "select 1 from pg_database where datname='crm_test'" | grep -q 1 || psql -U postgres -h localhost -c "create database crm_test;"
cd "$REPO"
if [ ! -f .env ]; then
	cp .env.example .env
	sed -i "s|^BETTER_AUTH_SECRET=\"\"|BETTER_AUTH_SECRET=\"$(openssl rand -base64 32)\"|" .env
	grep -q "^ALLOWED_SIGN_IN=\"[^\"]" .env || { sed -i "/^ALLOWED_SIGN_IN=/d" .env; echo "ALLOWED_SIGN_IN=\"fratex.ca\"" >> .env; }
fi
bun install
(cd packages/db && set -a && . ../../.env && set +a && bunx prisma migrate deploy && bunx prisma generate)
bun run db:test
bun run --cwd packages/db db:seed
cp "$JOURNAL/demo-seed.ts" packages/db/demo-seed.local.ts
(cd packages/db && set -a && . ../../.env && set +a && bun demo-seed.local.ts | grep COOKIE)
rm -f packages/db/demo-seed.local.ts
echo "Démarrer : cd $REPO && nohup bun run dev --filter=app --filter=api > /tmp/dev.log 2>&1 &"
