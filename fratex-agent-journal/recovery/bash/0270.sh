cd /tmp && python3 - <<'EOF'
import json
p="/root/.claude/projects/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58.jsonl"
lines=open(p).read().splitlines()
for i,line in enumerate(lines[:6]):
    o=json.loads(line)
    m=o.get("message") or {}
    c=m.get("content")
    s=json.dumps(c)[:400] if c is not None else json.dumps(o)[:400]
    print(i,o.get("type"),o.get("timestamp"),s,"\n")
o=json.loads(lines[-1]); print("last", o.get("timestamp"))
EOF