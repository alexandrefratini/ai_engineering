cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
import re
p="packages/ui/src/components/connection-list.tsx"
s=open(p).read()
s=s.replace('import type { ComponentType, ReactNode, SVGProps } from "react";','import type { ReactNode } from "react";')
s=s.replace('	logo: ComponentType<SVGProps<SVGSVGElement>>;','	logo: ReactNode;')
s=s.replace('''						const Logo = item.logo;
						return (''','''						return (''')
s=s.replace('''<Logo className="size-5" />''','''{item.logo}''')
open(p,"w").write(s)
D="apps/app/app/(app)/[slug]/settings/connections/"
for f,names in [("page.tsx",["GoogleLogo","MicrosoftLogo","SlackLogo"]),("sdr-connections-overview.tsx",["MetaLogo","TwilioLogo","GeminiLogo","GoogleCalendarLogo"])]:
    s=open(D+f).read()
    for n in names:
        s=s.replace(f"logo: {n},",f'logo: <{n} className="size-5" />,')
    open(D+f,"w").write(s)
EOF
grep -n "logo:" "apps/app/app/(app)/[slug]/settings/connections/page.tsx" "apps/app/app/(app)/[slug]/settings/connections/sdr-connections-overview.tsx"; bunx biome check --write packages/ui/src/components/connection-list.tsx "apps/app/app/(app)/[slug]/settings/connections" 2>&1 | tail -1; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -5; echo app $?)