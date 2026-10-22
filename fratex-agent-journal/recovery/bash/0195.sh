cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/api/src/real-estate/real-estate.service.ts"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:70]
    s=s.replace(a,b,1)
rep('''				appointments: {
					where: { agencyId: scope.agencyId },
					include: { client: { select: { name: true } } },
					orderBy: { startTime: "asc" },
				},
			},
		});
		if (!lead) throw new NotFoundException("Lead not found.");''','''				appointments: {
					where: { agencyId: scope.agencyId },
					include: { client: { select: { name: true } } },
					orderBy: { startTime: "asc" },
				},
				notes: {
					where: { agencyId: scope.agencyId },
					orderBy: { createdAt: "desc" },
					take: REAL_ESTATE.lead.noteLimit,
					include: { author: { select: { name: true } } },
				},
			},
		});
		if (!lead) throw new NotFoundException("Lead not found.");''')
rep('''			canWrite: canWriteAgency(scope.role),
			appointments: lead.appointments.map((item) => ({
				...item,
				clientName: item.client.name,
			})),
		};
	}''','''			canWrite: canWriteAgency(scope.role),
			canReassign: canWriteAgency(scope.role) && !scope.clientId,
			appointments: lead.appointments.map((item) => ({
				...item,
				clientName: item.client.name,
			})),
			notes: lead.notes.map((note) => ({
				id: note.id,
				body: note.body,
				createdAt: note.createdAt,
				authorName: note.author?.name ?? null,
			})),
		};
	}''')
rep('''	async getPipelineSummary(userId: string, input: PipelineSummaryInput) {''','''	async createLead(userId: string, input: z.infer<typeof createLeadInput>) {
		const scope = await this.access(userId, input.agencyId);
		this.write(scope.role);
		const clientId = scope.clientId ?? input.clientId ?? null;
		if (
			clientId &&
			!(await this.db.client.findFirst({
				where: { agencyId: scope.agencyId, id: clientId },
				select: { id: true },
			}))
		)
			throw new NotFoundException("Realtor not found.");
		const result = await this.db.$transaction(async (tx) => {
			await lockIdempotencyKey(tx, `phone:${scope.agencyId}:${input.phone}`);
			const existing = await tx.lead.findFirst({
				where: { agencyId: scope.agencyId, phone: input.phone },
				select: { id: true, clientId: true },
			});
			if (existing)
				return {
					id:
						!scope.clientId || existing.clientId === scope.clientId
							? existing.id
							: null,
					duplicate: true,
					assistantQueued: false,
				};
			const now = new Date();
			const lead = await tx.lead.create({
				data: {
					agencyId: scope.agencyId,
					clientId,
					firstName: input.firstName,
					lastName: input.lastName || null,
					phone: input.phone,
					email: input.email || null,
					intent: input.intent,
					source: input.source,
					consentedAt: input.smsConsent ? now : null,
					consentSource: input.smsConsent ? `manual:${userId}` : null,
				},
				select: { id: true },
			});
			await tx.attributionEvent.create({
				data: {
					id: `created:${lead.id}`,
					agencyId: scope.agencyId,
					leadId: lead.id,
					eventType: "LEAD_CREATED",
				},
			});
			if (input.note)
				await tx.leadNote.create({
					data: {
						agencyId: scope.agencyId,
						leadId: lead.id,
						authorId: userId,
						body: input.note,
					},
				});
			const assistantQueued = input.startAssistant && input.smsConsent;
			if (assistantQueued)
				await queueSdrTask(tx, {
					agencyId: scope.agencyId,
					leadId: lead.id,
					kind: "real-estate-qualify",
					key: `qualify:manual:${lead.id}`,
					payload: { agencyId: scope.agencyId, leadId: lead.id },
				});
			return { id: lead.id, duplicate: false, assistantQueued };
		});
		if (result.assistantQueued) this.agentTrigger.poke();
		return result;
	}
	private async scopedLead(
		scope: { agencyId: string; clientId?: string },
		leadId: string,
	) {
		const lead = await this.db.lead.findFirst({
			where: { id: leadId, agencyId: scope.agencyId, clientId: scope.clientId },
			select: { id: true, clientId: true, status: true },
		});
		if (!lead) throw new NotFoundException("Lead not found.");
		return lead;
	}
	async addNote(userId: string, input: z.infer<typeof addLeadNoteInput>) {
		const scope = await this.access(userId, input.agencyId);
		this.write(scope.role);
		const lead = await this.scopedLead(scope, input.leadId);
		const note = await this.db.leadNote.create({
			data: {
				agencyId: scope.agencyId,
				leadId: lead.id,
				authorId: userId,
				body: input.body,
			},
			include: { author: { select: { name: true } } },
		});
		return {
			id: note.id,
			body: note.body,
			createdAt: note.createdAt,
			authorName: note.author?.name ?? null,
		};
	}
	async createAppointment(
		userId: string,
		input: z.infer<typeof createAppointmentInput>,
	) {
		const scope = await this.access(userId, input.agencyId);
		this.write(scope.role);
		const lead = await this.scopedLead(scope, input.leadId);
		if (!lead.clientId)
			throw new BadRequestException(
				"Assignez d'abord un courtier à ce prospect.",
			);
		const clientId = lead.clientId;
		const startTime = new Date(input.startTime);
		const endTime = new Date(
			startTime.getTime() + input.durationMinutes * MINUTE_MS,
		);
		return this.db.$transaction(async (tx) => {
			const appointment = await tx.appointment.create({
				data: {
					agencyId: scope.agencyId,
					leadId: lead.id,
					clientId,
					title: input.title,
					description: input.location || null,
					startTime,
					endTime,
					status: "CONFIRMED",
				},
				select: { id: true },
			});
			if (lead.status !== "APPOINTMENT_HELD")
				await tx.lead.update({
					where: { id: lead.id, agencyId: scope.agencyId },
					data: { status: "APPOINTMENT_BOOKED" },
				});
			await this.recordConversion(
				tx,
				scope.agencyId,
				lead.id,
				`appointment:${appointment.id}`,
				"APPOINTMENT_SCHEDULED",
			);
			return appointment;
		});
	}
	private async recordConversion(
		tx: Prisma.TransactionClient,
		agencyId: string,
		leadId: string,
		id: string,
		eventType: "APPOINTMENT_SCHEDULED" | "APPOINTMENT_HELD",
	) {
		const attribution = await tx.attributionEvent.upsert({
			where: { id },
			update: {},
			create: { id, agencyId, leadId, eventType },
		});
		await queueSdrTask(tx, {
			agencyId,
			leadId,
			kind: "real-estate-capi",
			key: `capi:${attribution.id}`,
			payload: { agencyId, eventId: attribution.id },
		});
	}
	async updateAppointmentStatus(
		userId: string,
		input: z.infer<typeof updateAppointmentStatusInput>,
	) {
		const scope = await this.access(userId, input.agencyId);
		this.write(scope.role);
		const appointment = await this.db.appointment.findFirst({
			where: {
				id: input.appointmentId,
				agencyId: scope.agencyId,
				clientId: scope.clientId,
			},
			select: { id: true, leadId: true },
		});
		if (!appointment) throw new NotFoundException("Appointment not found.");
		await this.db.$transaction(async (tx) => {
			await tx.appointment.update({
				where: { id: appointment.id, agencyId: scope.agencyId },
				data: { status: input.status },
			});
			const lead = await tx.lead.findFirstOrThrow({
				where: { id: appointment.leadId, agencyId: scope.agencyId },
				select: { status: true },
			});
			if (input.status === "COMPLETED") {
				await tx.lead.update({
					where: { id: appointment.leadId, agencyId: scope.agencyId },
					data: { status: "APPOINTMENT_HELD" },
				});
				await this.recordConversion(
					tx,
					scope.agencyId,
					appointment.leadId,
					`held:${appointment.id}`,
					"APPOINTMENT_HELD",
				);
			}
			if (
				(input.status === "NO_SHOW" || input.status === "CANCELLED") &&
				lead.status === "APPOINTMENT_BOOKED" &&
				!(await tx.appointment.count({
					where: {
						agencyId: scope.agencyId,
						leadId: appointment.leadId,
						status: { in: ["SCHEDULED", "CONFIRMED"] },
					},
				}))
			)
				await tx.lead.update({
					where: { id: appointment.leadId, agencyId: scope.agencyId },
					data: { status: "QUALIFIED" },
				});
		});
		return { id: appointment.id };
	}
	async reassignLead(userId: string, input: z.infer<typeof reassignLeadInput>) {
		const scope = await this.access(userId, input.agencyId);
		this.write(scope.role);
		if (scope.clientId)
			throw new ForbiddenException("Agency staff reassign leads.");
		const lead = await this.scopedLead(scope, input.leadId);
		if (
			!(await this.db.client.findFirst({
				where: { agencyId: scope.agencyId, id: input.clientId },
				select: { id: true },
			}))
		)
			throw new NotFoundException("Realtor not found.");
		await this.db.lead.update({
			where: { id: lead.id, agencyId: scope.agencyId },
			data: { clientId: input.clientId },
		});
		return { id: lead.id };
	}
	async getPipelineSummary(userId: string, input: PipelineSummaryInput) {''')
rep('''import {
	calendarConnectLinkInput,
	configureCalendarInput,''','''import {
	addLeadNoteInput,
	calendarConnectLinkInput,
	configureCalendarInput,''')
rep('''	configureSmsInput,
	leadStatusEnum,''','''	configureSmsInput,
	createAppointmentInput,
	createLeadInput,
	leadStatusEnum,
	reassignLeadInput,''')
rep('''	suggestListingInput,
} from "./real-estate.contracts";''','''	suggestListingInput,
	updateAppointmentStatusInput,
} from "./real-estate.contracts";''')
open(p,"w").write(s)
p="apps/api/src/real-estate/real-estate-config.ts"
s=open(p).read()
s=s.replace("	lead: { eventLimit: 20, emailLimit: 20 },","	lead: { eventLimit: 20, emailLimit: 20, noteLimit: 50 },")
open(p,"w").write(s)
EOF
echo ok