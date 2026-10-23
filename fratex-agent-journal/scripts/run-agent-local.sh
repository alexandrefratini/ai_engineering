#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-/home/user/endsi3g/fratex-agent}"
JOURNAL="$(cd "$(dirname "$0")/.." && pwd)"
NODE_VERSION="${NODE_VERSION:-v24.22.1}"
NODE_DIR="/tmp/node24/node-${NODE_VERSION}-linux-x64"

if [ ! -x "$NODE_DIR/bin/node" ]; then
	mkdir -p /tmp/node24
	cd /tmp/node24
	curl -sSLO "https://nodejs.org/dist/latest-v24.x/node-${NODE_VERSION}-linux-x64.tar.xz"
	tar -xJf "node-${NODE_VERSION}-linux-x64.tar.xz"
fi

cd "$REPO"
bun install

if ! grep -q '^AGENT_BRIDGE_SECRET=' .env; then
	cat >> .env <<ENV

AGENT_URL="http://127.0.0.1:2000"
AGENT_BRIDGE_SECRET="$(openssl rand -base64 32)"
LLM_PROVIDER="openai-compatible"
LLM_BASE_URL="http://127.0.0.1:4010/v1"
LLM_MODEL="mock"
LLM_API_KEY="mock"
LLM_CONTEXT_WINDOW="32768"
ENV
fi

(cd /tmp && nohup bun "$JOURNAL/scripts/mock-llm.ts" > /tmp/mock-llm.log 2>&1 &)
sleep 1

cd apps/agent
(
	export PATH="$NODE_DIR/bin:$PATH"
	set -a
	. ../../.env
	set +a
	nohup bun run dev:headless > /tmp/agent.log 2>&1 &
)

echo "Agent en démarrage : suivre /tmp/agent.log, puis curl localhost:2000/eve/v1/health"
echo "Redémarrer aussi app et api pour qu'ils lisent AGENT_URL et AGENT_BRIDGE_SECRET."
