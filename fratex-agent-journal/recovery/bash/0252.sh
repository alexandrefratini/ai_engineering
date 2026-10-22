cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/components/team-presence.tsx"
s=open(p).read()
s=s.replace('''function MemberAvatar({ member, size, className }: { member: TeamMember; size: "sm" | "default"; className?: string }) {
	return (
		<Avatar size={size} className={className}>''','''function MemberAvatar({
	member,
	size,
	className,
	style,
}: {
	member: TeamMember;
	size: "sm" | "default";
	className?: string;
	style?: CSSProperties;
}) {
	return (
		<Avatar size={size} className={className} style={style}>''')
s=s.replace('''								{...{ style: { zIndex: VISIBLE - index } }}''','''								style={{ zIndex: VISIBLE - index }}''')
s=s.replace('import type { ReactNode } from "react";','import type { CSSProperties, ReactNode } from "react";')
open(p,"w").write(s)
EOF
(cd packages/ui && bunx tsc --noEmit 2>&1 | tail -3; echo ui $?); bunx biome check --write apps/app/components/team-presence-control.tsx apps/app/lib/navigation.ts apps/app/test/navigation.spec.ts 2>&1 | tail -1; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -3; echo app $?; bun test test/navigation.spec.ts 2>&1 | tail -3)