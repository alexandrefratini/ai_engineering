R=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad/recovered; mkdir -p $R/bash $R/reads $R/edits && python3 - "$R" <<'EOF'
import json, sys, os
R=sys.argv[1]
p="/root/.claude/projects/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58.jsonl"
uses={}; order=[]
results={}
for line in open(p):
    try: o=json.loads(line)
    except: continue
    m=o.get("message") or {}
    c=m.get("content")
    if not isinstance(c,list): continue
    for b in c:
        if not isinstance(b,dict): continue
        if b.get("type")=="tool_use":
            uses[b["id"]]=(b["name"],b["input"],o.get("timestamp"))
            order.append(b["id"])
        elif b.get("type")=="tool_result":
            cont=b.get("content")
            if isinstance(cont,list):
                cont="\n".join(x.get("text","") for x in cont if isinstance(x,dict))
            results[b["tool_use_id"]]=(cont, b.get("is_error"))
idx=open(f"{R}/INDEX.tsv","w")
for i,uid in enumerate(order):
    name,inp,ts=uses[uid]
    res,err=results.get(uid,("",None))
    tag=f"{i:04d}"
    if name=="Bash":
        open(f"{R}/bash/{tag}.sh","w").write(inp.get("command",""))
        open(f"{R}/bash/{tag}.out","w").write(str(res))
        idx.write(f"{tag}\t{ts}\tBash\t{'ERR' if err else ''}\t{inp.get('description','')}\n")
    elif name=="Read":
        open(f"{R}/reads/{tag}_{os.path.basename(inp.get('file_path',''))}.txt","w").write(inp.get("file_path","")+"\n"+str(res))
        idx.write(f"{tag}\t{ts}\tRead\t\t{inp.get('file_path')}\n")
    elif name in ("Edit","Write"):
        open(f"{R}/edits/{tag}_{name}.json","w").write(json.dumps(inp,ensure_ascii=False,indent=1))
        idx.write(f"{tag}\t{ts}\t{name}\t\t{inp.get('file_path')}\n")
    else:
        idx.write(f"{tag}\t{ts}\t{name}\t\t{json.dumps(inp,ensure_ascii=False)[:150]}\n")
idx.close()
print(len(order))
EOF
ls $R/bash | wc -l; ls $R/reads; head -5 $R/INDEX.tsv