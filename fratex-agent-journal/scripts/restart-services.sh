#!/usr/bin/env bash
# Relance tous les services locaux après un redémarrage du conteneur :
# Postgres, API (développement), application (version de production), faux modèle et agent.
# Utilisation : bash restart-services.sh [/chemin/vers/fratex-agent]
set -uo pipefail
REPO="${1:-/home/user/endsi3g/fratex-agent}"
JOURNAL="$(cd "$(dirname "$0")/.." && pwd)"
PGBIN=/usr/lib/postgresql/16/bin

if ! pg_isready -h localhost >/dev/null 2>&1; then
	chown postgres:postgres /tmp/pgdata
	rm -f /tmp/pgdata/postmaster.pid
	su postgres -c "$PGBIN/pg_ctl -D /tmp/pgdata -l /tmp/pg.log -o '-p 5432' start"
	sleep 3
fi

cd "$REPO"
(nohup bun run dev --filter=api > /tmp/dev-api.log 2>&1 &)
(cd apps/app && set -a && . ../../.env && set +a && nohup node node_modules/.bin/next start -p 3000 > /tmp/next-start.log 2>&1 &)
bash "$JOURNAL/scripts/run-agent-local.sh" > /tmp/run-agent.log 2>&1

echo "Attendre ~30 s puis vérifier :"
echo "  curl localhost:3000/sign-in  curl localhost:3001/health  curl localhost:2000/eve/v1/health"
echo "Rappel : "next start" exige une version compilée (cd apps/app && bunx next build) et, en mode production,"
echo "le cookie de session s'appelle __Secure-crm.session_token ; l'API en développement lit crm.session_token :"
echo "envoyer les deux cookies dans les essais. Ne jamais tuer un processus avec pkill -f sur un motif présent"
echo "dans sa propre commande : utiliser des PID explicites."
