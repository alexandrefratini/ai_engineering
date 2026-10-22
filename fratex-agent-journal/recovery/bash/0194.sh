cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/api/src/real-estate/real-estate.contracts.ts"
s=open(p).read()
def rep(a,b,count=1):
    global s
    assert a in s, a[:70]
    s=s.replace(a,b,count)
rep('''	lastInteractedAt: z.date().nullable(),
	createdAt: z.date(),
});''','''	lastInteractedAt: z.date().nullable(),
	createdAt: z.date(),
	source: z.string().nullable(),
});''')
rep('''		"RESCHEDULED",
	]),
	clientName: z.string(),
});''','''		"RESCHEDULED",
	]),
	description: z.string().nullable(),
	clientName: z.string(),
});

export const leadNoteOutput = z.object({
	id: z.string(),
	body: z.string(),
	createdAt: z.date(),
	authorName: z.string().nullable(),
});''')
rep('''	appointments: z.array(appointmentItemOutput),
	canWrite: z.boolean(),''','''	appointments: z.array(appointmentItemOutput),
	notes: z.array(leadNoteOutput),
	canWrite: z.boolean(),
	canReassign: z.boolean(),''')
rep('''export const updateLeadStatusInput = z.object({''','''export const leadSourceEnum = z.enum([
	"REFERRAL",
	"INBOUND_CALL",
	"WEBSITE",
	"SIGN",
	"OPEN_HOUSE",
	"SOCIAL",
	"OTHER",
]);
export const createLeadInput = z.object({
	agencyId: z.string().optional(),
	clientId: z.string().min(1).optional(),
	firstName: z.string().trim().min(1).max(80),
	lastName: z.string().trim().max(80).optional(),
	phone: northAmericanPhone,
	email: z.string().trim().email().optional(),
	source: leadSourceEnum,
	intent: leadIntentEnum.default("UNKNOWN"),
	note: z.string().trim().max(4000).optional(),
	smsConsent: z.boolean(),
	startAssistant: z.boolean(),
});
export const createLeadOutput = z.object({
	id: z.string().nullable(),
	duplicate: z.boolean(),
	assistantQueued: z.boolean(),
});
export const addLeadNoteInput = z.object({
	agencyId: z.string().optional(),
	leadId: z.string().min(1),
	body: z.string().trim().min(1).max(4000),
});
export const createAppointmentInput = z.object({
	agencyId: z.string().optional(),
	leadId: z.string().min(1),
	title: z.string().trim().min(1).max(120),
	startTime: z.string().datetime({ offset: true }),
	durationMinutes: z.number().int().min(15).max(480),
	location: z.string().trim().max(240).optional(),
});
export const appointmentOutcomeEnum = z.enum([
	"CONFIRMED",
	"COMPLETED",
	"NO_SHOW",
	"CANCELLED",
]);
export const updateAppointmentStatusInput = z.object({
	agencyId: z.string().optional(),
	appointmentId: z.string().min(1),
	status: appointmentOutcomeEnum,
});
export const reassignLeadInput = z.object({
	agencyId: z.string().optional(),
	leadId: z.string().min(1),
	clientId: z.string().min(1),
});
export const idOutput = z.object({ id: z.string() });

export const updateLeadStatusInput = z.object({''')
open(p,"w").write(s)
EOF
echo ok