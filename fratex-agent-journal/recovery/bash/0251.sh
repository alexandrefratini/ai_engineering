cd /home/user/endsi3g/fratex-agent && cat > packages/ui/src/components/team-presence.tsx <<'EOF'
"use client";

import type { ReactNode } from "react";
import { initialsFromName } from "../lib/format";
import { cn } from "../lib/utils";
import { Avatar, AvatarBadge, AvatarFallback, AvatarImage } from "./avatar";
import { Popover, PopoverContent, PopoverDescription, PopoverHeader, PopoverTitle, PopoverTrigger } from "./popover";

export type TeamMemberPage = { path: string; label: string };

export type TeamMember = {
	id: string;
	name: string;
	image: string | null;
	lastSeenAt: string | null;
	online: boolean;
	isSelf: boolean;
	page: TeamMemberPage | null;
};

const MINUTE_MS = 60_000;
const VISIBLE = 3;

function seenLabel(member: TeamMember, now: number) {
	if (member.online) return "En ligne";
	if (!member.lastSeenAt) return "Jamais connecté";
	const minutes = Math.max(1, Math.round((now - new Date(member.lastSeenAt).getTime()) / MINUTE_MS));
	if (minutes < 60) return `Vu il y a ${minutes} min`;
	const hours = Math.round(minutes / 60);
	if (hours < 24) return `Vu il y a ${hours} h`;
	return `Vu il y a ${Math.round(hours / 24)} j`;
}

function MemberAvatar({ member, size, className }: { member: TeamMember; size: "sm" | "default"; className?: string }) {
	return (
		<Avatar size={size} className={className}>
			{member.image ? <AvatarImage src={member.image} alt="" /> : null}
			<AvatarFallback>{initialsFromName(member.name)}</AvatarFallback>
			{member.online && <AvatarBadge />}
		</Avatar>
	);
}

function TeamList({
	members,
	renderPageLink,
}: {
	members: TeamMember[];
	renderPageLink: (page: TeamMemberPage) => ReactNode;
}) {
	const now = Date.now();
	return (
		<ul className="flex max-h-80 flex-col gap-2.5 overflow-auto">
			{members.map((member) => (
				<li key={member.id} className="flex items-center gap-2.5 text-sm">
					<MemberAvatar member={member} size="default" />
					<span className="flex min-w-0 flex-1 flex-col">
						<span className="truncate font-medium">
							{member.name}
							{member.isSelf && <span className="font-normal text-muted-foreground"> (vous)</span>}
						</span>
						<span className="truncate text-xs text-muted-foreground">
							{member.online && member.page && !member.isSelf ? (
								<>
									Sur{" "}
									<span className="text-foreground underline-offset-4 hover:underline">
										{renderPageLink(member.page)}
									</span>
								</>
							) : member.online && member.page ? (
								`Sur ${member.page.label}`
							) : (
								seenLabel(member, now)
							)}
						</span>
					</span>
				</li>
			))}
		</ul>
	);
}

export function TeamPresence({
	members,
	onlineCount,
	renderPageLink,
}: {
	members: TeamMember[];
	onlineCount: number;
	renderPageLink: (page: TeamMemberPage) => ReactNode;
}) {
	if (!members.length) return null;
	const visible = members.slice(0, VISIBLE);
	const hidden = members.length - visible.length;
	const summary = visible
		.map((member) => `${member.name}${member.online && member.page ? ` (${member.page.label})` : ""}`)
		.join(", ");
	return (
		<Popover>
			<PopoverTrigger asChild>
				<button
					type="button"
					aria-label={`Équipe : ${onlineCount} en ligne sur ${members.length}. ${summary}`}
					title={summary}
					className="hidden items-center gap-2 rounded-md px-1.5 py-1 transition-colors hover:bg-muted focus-visible:outline-2 focus-visible:outline-ring sm:flex"
				>
					<span className="flex items-center -space-x-2">
						{visible.map((member, index) => (
							<MemberAvatar
								key={member.id}
								member={member}
								size="sm"
								className={cn("ring-2 ring-background", !member.online && "opacity-70")}
								{...{ style: { zIndex: VISIBLE - index } }}
							/>
						))}
						{hidden > 0 && (
							<span className="relative flex size-6 items-center justify-center rounded-full bg-muted text-[10px] font-medium text-muted-foreground ring-2 ring-background">
								+{hidden}
							</span>
						)}
					</span>
					<span className="hidden text-xs text-muted-foreground lg:inline">{onlineCount} en ligne</span>
				</button>
			</PopoverTrigger>
			<PopoverContent align="end" className="w-80">
				<PopoverHeader>
					<PopoverTitle>Équipe</PopoverTitle>
					<PopoverDescription>
						{onlineCount} en ligne sur {members.length} membre{members.length > 1 ? "s" : ""}. Un clic sur une
						page vous y amène.
					</PopoverDescription>
				</PopoverHeader>
				<TeamList members={members} renderPageLink={renderPageLink} />
			</PopoverContent>
		</Popover>
	);
}
EOF
grep -n "function Avatar(" -A20 packages/ui/src/components/avatar.tsx | head -26