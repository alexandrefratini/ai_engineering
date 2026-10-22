cd /home/user/endsi3g/fratex-agent && cat > packages/ui/src/components/connection-list.tsx <<'EOF'
"use client";

import type { ComponentType, ReactNode, SVGProps } from "react";
import { REVEAL, staggerStyle } from "../lib/motion";
import { cn } from "../lib/utils";
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from "./card";
import { SegmentMeter } from "./real-estate-visuals";
import { Tooltip, TooltipContent, TooltipTrigger } from "./tooltip";

export type ConnectionState = "ready" | "partial" | "pending" | "missing";

export type ConnectionItem = {
	id: string;
	name: string;
	purpose: string;
	status: string;
	state: ConnectionState;
	explanation: string;
	detail?: ReactNode;
	logo: ComponentType<SVGProps<SVGSVGElement>>;
	action: ReactNode;
};

const DOT: Record<ConnectionState, string> = {
	ready: "bg-primary",
	partial: "bg-primary/50",
	pending: "bg-primary/50",
	missing: "bg-muted-foreground/40",
};

export function ConnectionList({
	title,
	description,
	items,
	progress,
	action,
	index = 0,
}: {
	title: string;
	description: string;
	items: ConnectionItem[];
	progress?: boolean;
	action?: ReactNode;
	index?: number;
}) {
	const ready = items.filter((item) => item.state === "ready").length;
	return (
		<Card className={REVEAL} style={staggerStyle(index)}>
			<CardHeader>
				<CardTitle>{title}</CardTitle>
				<CardDescription>{description}</CardDescription>
				{(progress || action) && (
					<CardAction className="flex items-center gap-3">
						{progress && (
							<span className="flex items-center gap-2 text-xs text-muted-foreground tabular-nums">
								<SegmentMeter filled={ready} total={items.length} label={`${ready} sur ${items.length} prêts`} />
								{ready}/{items.length} prêts
							</span>
						)}
						{action}
					</CardAction>
				)}
			</CardHeader>
			<CardContent>
				<ul className="-my-1 flex flex-col divide-y">
					{items.map((item, position) => {
						const Logo = item.logo;
						return (
							<li
								key={item.id}
								className={cn("flex flex-wrap items-center gap-x-3 gap-y-2 py-3 sm:flex-nowrap", REVEAL)}
								style={staggerStyle(position)}
							>
								<span className="flex size-9 shrink-0 items-center justify-center rounded-md border bg-background">
									<Logo className="size-5" />
								</span>
								<span className="flex min-w-0 flex-1 flex-col">
									<span className="text-sm font-medium">{item.name}</span>
									<span className="text-xs text-pretty text-muted-foreground">{item.purpose}</span>
								</span>
								{item.detail && (
									<span className="hidden w-40 shrink-0 truncate text-right text-xs text-muted-foreground tabular-nums md:inline">
										{item.detail}
									</span>
								)}
								<Tooltip>
									<TooltipTrigger asChild>
										<span
											tabIndex={0}
											className="flex w-44 shrink-0 items-center gap-1.5 rounded-sm text-xs outline-none focus-visible:ring-2 focus-visible:ring-ring"
										>
											<span aria-hidden="true" className={cn("size-2 shrink-0 rounded-full", DOT[item.state])} />
											<span className={cn("truncate", item.state === "missing" && "text-muted-foreground")}>
												{item.status}
											</span>
										</span>
									</TooltipTrigger>
									<TooltipContent className="block max-w-xs px-3 py-2 text-left">{item.explanation}</TooltipContent>
								</Tooltip>
								<span className="shrink-0">{item.action}</span>
							</li>
						);
					})}
				</ul>
			</CardContent>
		</Card>
	);
}
EOF
echo ok