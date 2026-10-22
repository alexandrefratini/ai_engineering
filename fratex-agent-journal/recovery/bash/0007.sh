cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/app/components/app-icon-rail.tsx"
s=open(p).read()
old_imports='''import Building from "@carbon/icons-react/es/Building";
import Calculator from "@carbon/icons-react/es/Calculator";
import Chat from "@carbon/icons-react/es/Chat";
import Close from "@carbon/icons-react/es/Close";
import Dashboard from "@carbon/icons-react/es/Dashboard";
import Events from "@carbon/icons-react/es/Events";
import Partnership from "@carbon/icons-react/es/Partnership";
import Settings from "@carbon/icons-react/es/Settings";
import UserMultiple from "@carbon/icons-react/es/UserMultiple";'''
new_imports='''import Analytics from "@carbon/icons-react/es/Analytics";
import Building from "@carbon/icons-react/es/Building";
import Calculator from "@carbon/icons-react/es/Calculator";
import Close from "@carbon/icons-react/es/Close";
import Events from "@carbon/icons-react/es/Events";
import Forum from "@carbon/icons-react/es/Forum";
import Home from "@carbon/icons-react/es/Home";
import IdManagement from "@carbon/icons-react/es/IdManagement";
import Portfolio from "@carbon/icons-react/es/Portfolio";
import Settings from "@carbon/icons-react/es/Settings";
import UserAvatar from "@carbon/icons-react/es/UserAvatar";
import UserMultiple from "@carbon/icons-react/es/UserMultiple";'''
assert old_imports in s
s=s.replace(old_imports,new_imports)
start=s.index("type RailItem = {")
end=s.index("function isActive(")
s=s[:start]+'''type RailItem = {
	title: string;
	href: string;
	icon: CarbonIcon;
	group: "real-estate" | "crm" | "system";
	iconClassName?: string;
	match: "exact" | "prefix";
	related?: string[];
};

const CHAT_HREF = "/chat";

const ITEMS: RailItem[] = [
	{
		title: "Accueil",
		href: "/",
		icon: Home,
		group: "real-estate",
		match: "exact",
	},
	{
		title: "Prospects",
		href: "/real-estate/leads",
		icon: UserMultiple,
		group: "real-estate",
		match: "prefix",
	},
	{
		title: "Pipeline",
		href: "/real-estate/pipeline",
		icon: Events,
		group: "real-estate",
		match: "prefix",
	},
	{
		title: "Boîte de réception",
		href: "/real-estate/inbox",
		icon: Forum,
		group: "real-estate",
		match: "prefix",
	},
	{
		title: "Courtiers",
		href: "/real-estate/realtors",
		icon: IdManagement,
		group: "real-estate",
		match: "prefix",
	},
	{
		title: "Portail courtier",
		href: "/real-estate/portal",
		icon: Analytics,
		group: "real-estate",
		match: "prefix",
	},
	{
		title: "Estimateur et offres",
		href: "/real-estate/valuation",
		icon: Calculator,
		group: "real-estate",
		match: "prefix",
	},
	{
		title: "Assistant IA",
		href: CHAT_HREF,
		icon: Bot,
		group: "crm",
		iconClassName: "size-5",
		match: "prefix",
		related: ["/agents"],
	},
	{
		title: "Contacts",
		href: "/contacts",
		icon: UserAvatar,
		group: "crm",
		match: "prefix",
	},
	{
		title: "Entreprises",
		href: "/companies",
		icon: Building,
		group: "crm",
		match: "prefix",
	},
	{
		title: "Affaires",
		href: "/deals",
		icon: Portfolio,
		group: "crm",
		match: "prefix",
	},
	{
		title: "Paramètres",
		href: "/settings",
		icon: Settings,
		group: "system",
		match: "prefix",
	},
];

function startsGroup<T extends Pick<RailItem, "group">>(
	items: T[],
	index: number,
): boolean {
	return index > 0 && items[index - 1]?.group !== items[index]?.group;
}

'''+s[end:]
s=s.replace('''					transitionTypes={[
						item.title === "Chat" ? "nav-forward" : "nav-lateral",
					]}''','''					transitionTypes={[
						item.section === CHAT_HREF ? "nav-forward" : "nav-lateral",
					]}''')
s=s.replace('''function MobileRailLink({
	item,
	active,
	onNavigate,
	onPrefetch,
}: {
	item: RailItem;''','''function MobileRailLink({
	item,
	active,
	onNavigate,
	onPrefetch,
}: {
	item: RailItem & { section: string };''')
s=s.replace('''	const inChat = items.some(
		(item) => item.title === "Chat" && isActive(item, pathname),
	);''','''	const inChat = items.some(
		(item) => item.section === CHAT_HREF && isActive(item, pathname),
	);''')
s=s.replace('''			{ITEMS.map((item) => (
				<Button
					key={item.href}
					variant="ghost"
					size="icon"
					disabled
					className="text-muted-foreground"
				>
					<Icon icon={item.icon} className={item.iconClassName} />
					<span className="sr-only">{item.title}</span>
				</Button>
			))}''','''			{ITEMS.map((item, index) => (
				<Fragment key={item.href}>
					{startsGroup(ITEMS, index) && <RailDivider />}
					<Button
						variant="ghost"
						size="icon"
						disabled
						className="text-muted-foreground"
					>
						<Icon icon={item.icon} className={item.iconClassName} />
						<span className="sr-only">{item.title}</span>
					</Button>
				</Fragment>
			))}''')
s=s.replace('''				{items.map((item) => (
					<RailLink
						key={item.href}
						item={item}
						active={isActive(item, pathname)}
						onPrefetch={() => prefetchSection(item.section)}
					/>
				))}''','''				{items.map((item, index) => (
					<Fragment key={item.href}>
						{startsGroup(items, index) && <RailDivider />}
						<RailLink
							item={item}
							active={isActive(item, pathname)}
							onPrefetch={() => prefetchSection(item.section)}
						/>
					</Fragment>
				))}''')
s=s.replace('''							{items.map((item) => (
								<MobileRailIconLink
									key={item.href}
									item={item}
									active={isActive(item, pathname)}
									onNavigate={() => setOpen(false)}
									onPrefetch={() => prefetchSection(item.section)}
								/>
							))}''','''							{items.map((item, index) => (
								<Fragment key={item.href}>
									{startsGroup(items, index) && <RailDivider />}
									<MobileRailIconLink
										item={item}
										active={isActive(item, pathname)}
										onNavigate={() => setOpen(false)}
										onPrefetch={() => prefetchSection(item.section)}
									/>
								</Fragment>
							))}''')
s=s.replace('''							{items.map((item) => (
								<MobileRailLink
									key={item.href}
									item={item}
									active={isActive(item, pathname)}
									onNavigate={() => setOpen(false)}
									onPrefetch={() => prefetchSection(item.section)}
								/>
							))}''','''							{items.map((item, index) => (
								<Fragment key={item.href}>
									{startsGroup(items, index) && (
										<div className="my-1 h-px bg-border" />
									)}
									<MobileRailLink
										item={item}
										active={isActive(item, pathname)}
										onNavigate={() => setOpen(false)}
										onPrefetch={() => prefetchSection(item.section)}
									/>
								</Fragment>
							))}''')
s=s.replace('''function RailLink({''','''function RailDivider() {
	return <div aria-hidden="true" className="my-1 h-px w-5 bg-border" />;
}

function RailLink({''',1)
s=s.replace('import { useMemo } from "react";','import { Fragment, useMemo } from "react";')
s=s.replace('<SheetTitle>Navigation and agent chats</SheetTitle>','<SheetTitle>Navigation et conversations IA</SheetTitle>')
s=s.replace('aria-label="Close navigation"','aria-label="Fermer la navigation"')
s=s.replace('aria-label="Primary"','aria-label="Navigation principale"')
open(p,"w").write(s)
EOF
grep -n "Primary\|Close navigation\|\"Chat\"" apps/app/components/app-icon-rail.tsx; bunx biome check --write apps/app/components/app-icon-rail.tsx 2>&1 | tail -3; cd apps/app && bunx tsc --noEmit; echo tsc $?