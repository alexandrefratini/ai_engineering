cd /tmp && python3 - <<'EOF'
import json, collections
p="/root/.claude/projects/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58.jsonl"
counts=collections.Counter(); types=collections.Counter(); n=0
first_ts=None
for line in open(p):
    n+=1
    try: o=json.loads(line)
    except: continue
    types[o.get("type")]+=1
    m=o.get("message") or {}
    c=m.get("content")
    if isinstance(c,list):
        for b in c:
            if isinstance(b,dict) and b.get("type")=="tool_use":
                counts[b.get("name")]+=1
print(n, types.most_common())
print(counts.most_common())
EOF