cd /home/user/endsi3g/fratex-agent/apps/api/test && cat > real-estate-calendar.integration.spec.ts <<'EOF'
import { afterAll, afterEach, beforeAll, describe, expect, it } from "bun:test";
import { randomUUID } from "node:crypto";
import { db } from "@crm/db";
import { AgentTriggerService } from "../src/agent/agent-trigger.service";
import {
	readCalendarState,
	signCalendarState,
} from "../src/real-estate/calendar-state";
import { RealEstateService } from "../src/real-estate/real-estate.service";

const suffix = randomUUID();
const agency = `calendar-agency-${suffix}`;
const owner = `calendar-owner-${suffix}`;
const member = `calendar-member-${suffix}`;
const realtor = `calendar-realtor-${suffix}`;
const secret = "calendar-test-secret-with-enough-length";
const trigger = new AgentTriggerService(db);
trigger.poke = () => {};
const service = new RealEstateService(db, trigger);
const hours = {
	timezone: "America/Toronto",
	days: [1, 2, 3, 4, 5],
	startHour: 9,
	endHour: 17,
};
const saved = {
	id: process.env.GOOGLE_CLIENT_ID,
	secret: process.env.GOOGLE_CLIENT_SECRET,
	auth: process.env.BETTER_AUTH_SECRET,
	fetch: globalThis.fetch,
};

beforeAll(async () => {
	await db.user.createMany({
		data: [owner, member].map((id) => ({
			id,
			name: id,
			email: `${id}@example.test`,
		})),
	});
	await db.agency.create({
		data: { id: agency, name: "Calendrier", slug: agency },
	});
	await db.agencyUser.createMany({
		data: [
			{ agencyId: agency, userId: owner, role: "OWNER" },
			{ agencyId: agency, userId: member, role: "MEMBER" },
		],
	});
	await db.client.create({
		data: {
			id: realtor,
			agencyId: agency,
			name: "Courtier Agenda",
			email: `${realtor}@example.test`,
			targetZones: ["Laval"],
		},
	});
});

afterEach(() => {
	process.env.GOOGLE_CLIENT_ID = saved.id;
	process.env.GOOGLE_CLIENT_SECRET = saved.secret;
	process.env.BETTER_AUTH_SECRET = saved.auth;
	globalThis.fetch = saved.fetch;
});

afterAll(async () => {
	await db.agency.deleteMany({ where: { id: agency } });
	await db.user.deleteMany({ where: { id: { in: [owner, member] } } });
});

describe("calendar state", () => {
	const state = {
		agencyId: agency,
		clientId: realtor,
		hours,
		slotDuration: 30,
		expiresAt: Date.now() + 60_000,
	};

	it("round-trips a signed state", () => {
		const token = signCalendarState(state, secret);
		expect(readCalendarState(token, secret, Date.now())).toEqual(state);
	});

	it("rejects a tampered, foreign or expired state", () => {
		const token = signCalendarState(state, secret);
		const [body, mac] = token.split(".");
		const forged = Buffer.from(
			JSON.stringify({ ...state, clientId: "someone-else" }),
		).toString("base64url");
		expect(readCalendarState(`${forged}.${mac}`, secret, Date.now())).toBeNull();
		expect(readCalendarState(`${body}.${mac}`, "another-secret", Date.now())).toBeNull();
		expect(readCalendarState(token, secret, state.expiresAt + 1)).toBeNull();
		expect(readCalendarState("not-a-token", secret, Date.now())).toBeNull();
	});
});

describe("realtor calendar connection", () => {
	it("returns no link when Google credentials are missing", async () => {
		delete process.env.GOOGLE_CLIENT_ID;
		delete process.env.GOOGLE_CLIENT_SECRET;
		const link = await service.calendarConnectLink(owner, {
			agencyId: agency,
			clientId: realtor,
			...hours,
			slotDuration: 30,
		});
		expect(link).toEqual({ url: null, expiresAt: null });
		const status = await service.getConnectionsStatus(owner, agency);
		expect(status.calendar).toEqual({
			oauthAvailable: false,
			connected: 0,
			total: 1,
		});
	});

	it("refuses members who cannot manage the agency", async () => {
		await expect(
			service.calendarConnectLink(member, {
				agencyId: agency,
				clientId: realtor,
				...hours,
				slotDuration: 30,
			}),
		).rejects.toThrow();
	});

	it("builds a consent link and stores the realtor's tokens on callback", async () => {
		process.env.GOOGLE_CLIENT_ID = "client-id.apps.googleusercontent.com";
		process.env.GOOGLE_CLIENT_SECRET = "client-secret";
		process.env.BETTER_AUTH_SECRET = secret;
		const link = await service.calendarConnectLink(owner, {
			agencyId: agency,
			clientId: realtor,
			...hours,
			startHour: 10,
			slotDuration: 45,
		});
		expect(link.url).not.toBeNull();
		const url = new URL(link.url ?? "");
		expect(url.searchParams.get("access_type")).toBe("offline");
		expect(url.searchParams.get("prompt")).toBe("consent");
		expect(url.searchParams.get("scope")).toContain("calendar.freebusy");
		expect(url.searchParams.get("redirect_uri")).toEndWith(
			"/api/real-estate/calendar/callback",
		);
		const sent: URLSearchParams[] = [];
		globalThis.fetch = (async (_input: unknown, init?: RequestInit) => {
			sent.push(init?.body as URLSearchParams);
			return Response.json({
				access_token: "access-token-from-google",
				refresh_token: "refresh-token-from-google",
				expires_in: 3599,
				scope:
					"https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.freebusy",
			});
		}) as typeof fetch;
		const result = await service.completeCalendarConnection(
			"authorization-code",
			url.searchParams.get("state") ?? "",
		);
		expect(result).toEqual({ ok: true });
		expect(sent[0]?.get("grant_type")).toBe("authorization_code");
		expect(sent[0]?.get("code")).toBe("authorization-code");
		const calendar = await db.realtorCalendar.findUniqueOrThrow({
			where: { clientId: realtor },
		});
		expect(calendar.calendarId).toBe("primary");
		expect(calendar.refreshToken).toBe("refresh-token-from-google");
		expect(calendar.slotDuration).toBe(45);
		expect(calendar.workingHours).toMatchObject({ startHour: 10, endHour: 17 });
		const status = await service.getConnectionsStatus(owner, agency);
		expect(status.calendar).toEqual({
			oauthAvailable: true,
			connected: 1,
			total: 1,
		});
	});

	it("refuses a callback whose consent misses a calendar scope", async () => {
		process.env.GOOGLE_CLIENT_ID = "client-id.apps.googleusercontent.com";
		process.env.GOOGLE_CLIENT_SECRET = "client-secret";
		process.env.BETTER_AUTH_SECRET = secret;
		const state = signCalendarState(
			{
				agencyId: agency,
				clientId: realtor,
				hours,
				slotDuration: 30,
				expiresAt: Date.now() + 60_000,
			},
			secret,
		);
		globalThis.fetch = (async () =>
			Response.json({
				access_token: "access",
				refresh_token: "refresh",
				expires_in: 3599,
				scope: "https://www.googleapis.com/auth/calendar.events",
			})) as unknown as typeof fetch;
		expect(await service.completeCalendarConnection("code", state)).toEqual({
			ok: false,
			reason: "scope",
		});
	});
});
EOF
cd .. && bunx biome check --write test/real-estate-calendar.integration.spec.ts >/dev/null 2>&1; CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts test/real-estate-calendar.integration.spec.ts 2>&1 | tail -15