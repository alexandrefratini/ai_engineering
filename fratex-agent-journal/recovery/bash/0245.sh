cd /home/user/endsi3g/fratex-agent && grep -n "  lastSeenAt" packages/db/prisma/schema.prisma && python3 - <<'EOF'
p="packages/db/prisma/schema.prisma"
s=open(p).read()
import re
i=s.index("model User {")
j=s.index("lastSeenAt",i)
line_end=s.index("\n",j)
s=s[:line_end+1]+"  lastSeenPath  String?\n  lastSeenLabel String?\n"+s[line_end+1:]
open(p,"w").write(s)
EOF
cd packages/db && set -a && . ../../.env && set +a && bunx prisma format >/dev/null 2>&1; bunx prisma migrate dev --create-only --name add_user_presence_page 2>&1 | tail -2; cat prisma/migrations/*_add_user_presence_page/migration.sql; bunx prisma migrate deploy 2>&1 | tail -1; bunx prisma generate 2>&1 | tail -1; cd ../.. && bun run db:test 2>&1 | tail -1