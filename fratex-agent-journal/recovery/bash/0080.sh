cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/api/src/real-estate/real-estate.contracts.ts"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:60]
    s=s.replace(a,b,1)
rep('''	google: z.object({
		connected: z.boolean(),
	}),
	microsoft: z.object({
		connected: z.boolean(),
	}),
});''','''	google: z.object({
		connected: z.boolean(),
	}),
	microsoft: z.object({
		connected: z.boolean(),
	}),
	calendar: z.object({
		oauthAvailable: z.boolean(),
		connected: z.number().int().nonnegative(),
		total: z.number().int().nonnegative(),
	}),
});''')
rep('''export const configurationOutput = z.object({ configured: z.boolean() });''','''export const configurationOutput = z.object({ configured: z.boolean() });

export const calendarConnectLinkInput = z.object({
	agencyId: z.string().optional(),
	clientId: z.string().min(1),
	timezone: z.string(),
	days: z.array(z.number().int().min(0).max(6)).min(1),
	startHour: z.number().int().min(0).max(23),
	endHour: z.number().int().min(1).max(24),
	slotDuration: z.number().int().min(15).max(120),
});
export const calendarConnectLinkOutput = z.object({
	url: z.string().url().nullable(),
	expiresAt: z.string().nullable(),
});''')
open(p,"w").write(s)

p="apps/api/src/real-estate/real-estate.router.ts"
s=open(p).read()
rep('''	clientDetailOutput,
	configurationOutput,''','''	calendarConnectLinkInput,
	calendarConnectLinkOutput,
	clientDetailOutput,
	configurationOutput,''')
rep('''		return this.realEstateService.configureCalendar(ctx.user.id, input);
	}
}''','''		return this.realEstateService.configureCalendar(ctx.user.id, input);
	}
	@Mutation({
		input: calendarConnectLinkInput,
		output: calendarConnectLinkOutput,
	})
	async calendarConnectLink(
		@Ctx() ctx: AuthedTrpcContext,
		@Input() input: z.infer<typeof calendarConnectLinkInput>,
	) {
		return this.realEstateService.calendarConnectLink(ctx.user.id, input);
	}
}''')
open(p,"w").write(s)

p="apps/api/src/real-estate/real-estate.service.ts"
s=open(p).read()
rep('''	async getConnectionsStatus(userId: string, requestedAgencyId?: string) {''','''	private googleCredentials() {
		const clientId = process.env.GOOGLE_CLIENT_ID?.trim();
		const clientSecret = process.env.GOOGLE_CLIENT_SECRET?.trim();
		return clientId && clientSecret ? { clientId, clientSecret } : null;
	}
	private calendarRedirectUri() {
		return `${process.env.API_URL ?? "http://localhost:3001"}${REAL_ESTATE.calendar.callbackPath}`;
	}
	async calendarConnectLink(
		userId: string,
		input: z.infer<typeof calendarConnectLinkInput>,
	) {
		const scope = await this.access(userId, input.agencyId, input.clientId);
		this.write(scope.role, true);
		if (
			!(await this.db.client.findFirst({
				where: { agencyId: scope.agencyId, id: input.clientId },
			}))
		)
			throw new NotFoundException("Realtor not found.");
		const hours = workingHours.parse({
			timezone: input.timezone,
			days: input.days,
			startHour: input.startHour,
			endHour: input.endHour,
		});
		try {
			new Intl.DateTimeFormat("fr-CA", { timeZone: hours.timezone });
		} catch {
			throw new BadRequestException("Invalid timezone.");
		}
		const google = this.googleCredentials();
		const secret = process.env.BETTER_AUTH_SECRET;
		if (!google || !secret) return { url: null, expiresAt: null };
		const expiresAt = Date.now() + REAL_ESTATE.calendar.linkTtlMs;
		const state = signCalendarState(
			{
				agencyId: scope.agencyId,
				clientId: input.clientId,
				hours,
				slotDuration: input.slotDuration,
				expiresAt,
			},
			secret,
		);
		const url = new URL(REAL_ESTATE.calendar.authorizeUrl);
		url.search = new URLSearchParams({
			client_id: google.clientId,
			redirect_uri: this.calendarRedirectUri(),
			response_type: "code",
			access_type: "offline",
			prompt: "consent",
			include_granted_scopes: "true",
			scope: REAL_ESTATE.calendar.scopes.join(" "),
			state,
		}).toString();
		return { url: url.toString(), expiresAt: new Date(expiresAt).toISOString() };
	}
	async completeCalendarConnection(code: string, token: string) {
		const google = this.googleCredentials();
		const secret = process.env.BETTER_AUTH_SECRET;
		if (!google || !secret) return { ok: false as const, reason: "config" };
		const state = readCalendarState(token, secret, Date.now());
		if (!state) return { ok: false as const, reason: "expired" };
		const client = await this.db.client.findFirst({
			where: { agencyId: state.agencyId, id: state.clientId },
			select: { id: true },
		});
		if (!client) return { ok: false as const, reason: "realtor" };
		let tokens: z.infer<typeof googleAuthorizationResponse>;
		try {
			const response = await fetch(REAL_ESTATE.calendar.tokenUrl, {
				method: "POST",
				body: new URLSearchParams({
					client_id: google.clientId,
					client_secret: google.clientSecret,
					code,
					grant_type: "authorization_code",
					redirect_uri: this.calendarRedirectUri(),
				}),
				signal: AbortSignal.timeout(REAL_ESTATE.calendar.timeoutMs),
			});
			if (!response.ok) return { ok: false as const, reason: "google" };
			const parsed = googleAuthorizationResponse.safeParse(
				await response.json(),
			);
			if (!parsed.success) return { ok: false as const, reason: "google" };
			tokens = parsed.data;
		} catch {
			return { ok: false as const, reason: "google" };
		}
		const granted = tokens.scope.split(" ");
		if (
			tokens.scope &&
			!REAL_ESTATE.calendar.scopes.every((item) => granted.includes(item))
		)
			return { ok: false as const, reason: "scope" };
		const data = {
			agencyId: state.agencyId,
			clientId: state.clientId,
			provider: "google",
			calendarId: REAL_ESTATE.calendar.calendarId,
			accessToken: tokens.access_token,
			refreshToken: tokens.refresh_token,
			tokenExpiry: new Date(Date.now() + tokens.expires_in * 1000),
			workingHours: state.hours,
			slotDuration: state.slotDuration,
		};
		await this.db.realtorCalendar.upsert({
			where: { clientId: state.clientId },
			create: data,
			update: data,
		});
		return { ok: true as const };
	}
	async getConnectionsStatus(userId: string, requestedAgencyId?: string) {''')
rep('''		const [accounts, formCount, sms, receipt, model, calendar] =
			await Promise.all([''','''		const [accounts, formCount, sms, receipt, model, calendar, realtors] =
			await Promise.all([''')
rep('''				this.db.realtorCalendar.count({
					where: { agencyId: scope.agencyId, clientId: scope.clientId },
				}),
			]);''','''				this.db.realtorCalendar.count({
					where: { agencyId: scope.agencyId, clientId: scope.clientId },
				}),
				this.db.client.count({
					where: { agencyId: scope.agencyId, id: scope.clientId },
				}),
			]);''')
rep('''			google: { connected: calendar > 0 },
			microsoft: { connected: false },
		};''','''			google: { connected: calendar > 0 },
			microsoft: { connected: false },
			calendar: {
				oauthAvailable: Boolean(
					this.googleCredentials() && process.env.BETTER_AUTH_SECRET,
				),
				connected: calendar,
				total: realtors,
			},
		};''')
rep('''	configureCalendarInput,
	configureMetaInput,''','''	calendarConnectLinkInput,
	configureCalendarInput,
	configureMetaInput,''')
open(p,"w").write(s)
EOF
sed -n 1,38p apps/api/src/real-estate/real-estate.service.ts | grep -n "import\|from" | head -30