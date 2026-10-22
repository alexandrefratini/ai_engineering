cd /home/user/endsi3g/fratex-agent && cat > apps/api/src/presence/presence.contracts.ts <<'EOF'
import { z } from "zod";

export const heartbeatInput = z
	.object({
		path: z
			.string()
			.max(300)
			.regex(/^\/[^\s]*$/),
		label: z.string().trim().min(1).max(80),
	})
	.optional();

export const teamPresenceOutput = z.object({
	members: z.array(
		z.object({
			id: z.string(),
			name: z.string(),
			image: z.string().nullable(),
			lastSeenAt: z.date().nullable(),
			online: z.boolean(),
			isSelf: z.boolean(),
			page: z.object({ path: z.string(), label: z.string() }).nullable(),
		}),
	),
	onlineCount: z.number(),
});

export const heartbeatOutput = z.object({ lastSeenAt: z.date() });
EOF
python3 - <<'EOF'
p="/home/user/endsi3g/fratex-agent/apps/api/src/presence/presence.service.ts"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:60]
    s=s.replace(a,b,1)
rep('''	async heartbeat(userId: string) {
		const lastSeenAt = new Date();
		await this.db.user.update({
			where: { id: userId },
			data: { lastSeenAt },
			select: { id: true },
		});
		return { lastSeenAt };
	}''','''	async heartbeat(userId: string, page?: { path: string; label: string }) {
		const lastSeenAt = new Date();
		await this.db.user.update({
			where: { id: userId },
			data: {
				lastSeenAt,
				...(page ? { lastSeenPath: page.path, lastSeenLabel: page.label } : {}),
			},
			select: { id: true },
		});
		return { lastSeenAt };
	}''')
rep('''		const rows = await this.db.user.findMany({
			where: { members: { some: {} } },
			select: { id: true, name: true, image: true, lastSeenAt: true },''','''		const memberships = await this.db.member.findMany({
			where: { userId },
			select: { organizationId: true },
		});
		const rows = await this.db.user.findMany({
			where: {
				members: {
					some: {
						organizationId: {
							in: memberships.map((item) => item.organizationId),
						},
					},
				},
			},
			select: {
				id: true,
				name: true,
				image: true,
				lastSeenAt: true,
				lastSeenPath: true,
				lastSeenLabel: true,
			},''')
rep('''		const members = rows.map((row) => ({
			...row,
			online: row.lastSeenAt !== null && row.lastSeenAt.getTime() >= since,
			isSelf: row.id === userId,
		}));''','''		const members = rows.map(
			({ lastSeenPath, lastSeenLabel, ...row }) => {
				const online =
					row.lastSeenAt !== null && row.lastSeenAt.getTime() >= since;
				return {
					...row,
					online,
					isSelf: row.id === userId,
					page:
						online && lastSeenPath && lastSeenLabel
							? { path: lastSeenPath, label: lastSeenLabel }
							: null,
				};
			},
		);''')
open(p,"w").write(s)
p="/home/user/endsi3g/fratex-agent/apps/api/src/presence/presence.router.ts"
s=open(p).read()
s=s.replace('''import { Ctx, Mutation, Query, Router, UseMiddlewares } from "nestjs-trpc";''','''import {
	Ctx,
	Input,
	Mutation,
	Query,
	Router,
	UseMiddlewares,
} from "nestjs-trpc";
import type { z } from "zod";''')
s=s.replace('''import { heartbeatOutput, teamPresenceOutput } from "./presence.contracts";''','''import {
	heartbeatInput,
	heartbeatOutput,
	teamPresenceOutput,
} from "./presence.contracts";''')
s=s.replace('''	@Mutation({ output: heartbeatOutput })
	async heartbeat(@Ctx() ctx: AuthedTrpcContext) {
		return this.presence.heartbeat(ctx.user.id);
	}''','''	@Mutation({ input: heartbeatInput, output: heartbeatOutput })
	async heartbeat(
		@Ctx() ctx: AuthedTrpcContext,
		@Input() input: z.infer<typeof heartbeatInput>,
	) {
		return this.presence.heartbeat(ctx.user.id, input);
	}''')
open(p,"w").write(s)
p="/home/user/endsi3g/fratex-agent/apps/api/test/presence.integration.spec.ts"
s=open(p).read()
s=s.replace('''const outsider = `presence-outsider-${suffix}`;''','''const outsider = `presence-outsider-${suffix}`;
const foreign = `presence-foreign-${suffix}`;
const elsewhere = `presence-elsewhere-org-${suffix}`;''')
s=s.replace('''		data: [active, idle, outsider].map((id) => ({''','''		data: [active, idle, outsider, foreign].map((id) => ({''')
s=s.replace('''	await db.member.createMany({
		data: [active, idle].map((userId) => ({
			id: `${userId}-member`,
			organizationId: organization,
			userId,
			createdAt: new Date(),
		})),
	});''','''	await db.organization.create({
		data: {
			id: elsewhere,
			name: "Ailleurs",
			slug: elsewhere,
			createdAt: new Date(),
		},
	});
	await db.member.createMany({
		data: [
			...[active, idle].map((userId) => ({
				id: `${userId}-member`,
				organizationId: organization,
				userId,
				createdAt: new Date(),
			})),
			{
				id: `${foreign}-member`,
				organizationId: elsewhere,
				userId: foreign,
				createdAt: new Date(),
			},
		],
	});''')
s=s.replace('''	await db.organization.deleteMany({ where: { id: organization } });
	await db.user.deleteMany({ where: { id: { in: [active, idle, outsider] } } });''','''	await db.organization.deleteMany({
		where: { id: { in: [organization, elsewhere] } },
	});
	await db.user.deleteMany({
		where: { id: { in: [active, idle, outsider, foreign] } },
	});''')
s=s.replace('''		await service.heartbeat(active);
		const team = await service.team(active);''','''		await service.heartbeat(active, {
			path: "/real-estate/inbox",
			label: "Boîte de réception",
		});
		await service.heartbeat(foreign);
		const team = await service.team(active);''')
s=s.replace('''		expect(byId.has(outsider)).toBe(false);
	});''','''		expect(byId.has(outsider)).toBe(false);
		expect(byId.has(foreign)).toBe(false);
		expect(byId.get(active)?.page).toEqual({
			path: "/real-estate/inbox",
			label: "Boîte de réception",
		});
		expect(byId.get(idle)?.page).toBeNull();
	});''')
open(p,"w").write(s)
EOF
bunx biome check --write apps/api/src/presence apps/api/test/presence.integration.spec.ts 2>&1 | tail -1; cd apps/api && bunx tsc --noEmit -p tsconfig.json 2>&1 | tail -5; echo api $?; CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts test/presence.integration.spec.ts 2>&1 | tail -4