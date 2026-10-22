cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/api/src/real-estate/real-estate-config.ts"
s=open(p).read()
s=s.replace('''	email: { gmailWebBase: "https://mail.google.com/mail/u/0/#all/" },
} as const;''','''	email: { gmailWebBase: "https://mail.google.com/mail/u/0/#all/" },
	calendar: {
		authorizeUrl: "https://accounts.google.com/o/oauth2/v2/auth",
		tokenUrl: "https://oauth2.googleapis.com/token",
		scopes: [
			"https://www.googleapis.com/auth/calendar.events",
			"https://www.googleapis.com/auth/calendar.freebusy",
		],
		calendarId: "primary",
		callbackPath: "/api/real-estate/calendar/callback",
		resultPath: "/agenda-connecte",
		linkTtlMs: 7 * DAY_MS,
		timeoutMs: 10_000,
	},
} as const;''')
open(p,"w").write(s)

p="packages/validation/src/real-estate.ts"
s=open(p).read()
s=s.replace('''export const googleRefreshResponse = z.object({
	access_token: z.string().min(1),
	expires_in: z.number().positive(),
});''','''export const googleRefreshResponse = z.object({
	access_token: z.string().min(1),
	expires_in: z.number().positive(),
});

export const googleAuthorizationResponse = googleRefreshResponse.extend({
	refresh_token: z.string().min(1),
	scope: z.string().default(""),
});

export const calendarConnectState = z.object({
	agencyId: z.string().min(1),
	clientId: z.string().min(1),
	hours: z.object({
		timezone: z.string(),
		days: z.array(z.number().int().min(0).max(6)).min(1),
		startHour: z.number().int().min(0).max(23),
		endHour: z.number().int().min(1).max(24),
	}),
	slotDuration: z.number().int().min(15).max(120),
	expiresAt: z.number().int().positive(),
});''')
open(p,"w").write(s)
EOF
cat > apps/api/src/real-estate/calendar-state.ts <<'EOF'
import { createHmac, timingSafeEqual } from "node:crypto";
import { calendarConnectState } from "@crm/validation/real-estate";
import type { z } from "zod";

export type CalendarConnectState = z.infer<typeof calendarConnectState>;

function signature(body: string, secret: string) {
	return createHmac("sha256", secret)
		.update(`realtor-calendar:${body}`)
		.digest("base64url");
}

export function signCalendarState(
	state: CalendarConnectState,
	secret: string,
): string {
	const body = Buffer.from(JSON.stringify(state)).toString("base64url");
	return `${body}.${signature(body, secret)}`;
}

export function readCalendarState(
	token: string,
	secret: string,
	now: number,
): CalendarConnectState | null {
	const [body, mac] = token.split(".");
	if (!body || !mac) return null;
	const expected = Buffer.from(signature(body, secret));
	const received = Buffer.from(mac);
	if (
		expected.length !== received.length ||
		!timingSafeEqual(expected, received)
	)
		return null;
	let decoded: unknown;
	try {
		decoded = JSON.parse(Buffer.from(body, "base64url").toString("utf8"));
	} catch {
		return null;
	}
	const parsed = calendarConnectState.safeParse(decoded);
	if (!parsed.success || parsed.data.expiresAt <= now) return null;
	return parsed.data;
}
EOF
echo ok