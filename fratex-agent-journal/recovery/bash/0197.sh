cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/api/src/real-estate/real-estate.router.ts"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:70]
    s=s.replace(a,b,1)
rep('''	updateLeadStatusInput,''','''	updateAppointmentStatusInput,
	updateLeadStatusInput,''')
rep('''	calendarConnectLinkInput,''','''	addLeadNoteInput,
	calendarConnectLinkInput,''')
rep('''	createClientInput,''','''	createAppointmentInput,
	createClientInput,
	createLeadInput,
	createLeadOutput,''')
rep('''	leadDetailOutput,''','''	idOutput,
	leadDetailOutput,
	leadNoteOutput,''')
rep('''	realtorPortalInput,''','''	realtorPortalInput,
	reassignLeadInput,''')
rep('''	async updateStatus(''','''	async updateStatusPlaceholder() {}
	async updateStatus(''')
s=s.replace('''	async updateStatusPlaceholder() {}
''','')
idx=s.rindex("}\n")
s=s[:idx]+'''	@Mutation({ input: createLeadInput, output: createLeadOutput })
	async createLead(
		@Ctx() ctx: AuthedTrpcContext,
		@Input() input: z.infer<typeof createLeadInput>,
	) {
		return this.realEstateService.createLead(ctx.user.id, input);
	}
	@Mutation({ input: addLeadNoteInput, output: leadNoteOutput })
	async addNote(
		@Ctx() ctx: AuthedTrpcContext,
		@Input() input: z.infer<typeof addLeadNoteInput>,
	) {
		return this.realEstateService.addNote(ctx.user.id, input);
	}
	@Mutation({ input: createAppointmentInput, output: idOutput })
	async createAppointment(
		@Ctx() ctx: AuthedTrpcContext,
		@Input() input: z.infer<typeof createAppointmentInput>,
	) {
		return this.realEstateService.createAppointment(ctx.user.id, input);
	}
	@Mutation({ input: updateAppointmentStatusInput, output: idOutput })
	async updateAppointmentStatus(
		@Ctx() ctx: AuthedTrpcContext,
		@Input() input: z.infer<typeof updateAppointmentStatusInput>,
	) {
		return this.realEstateService.updateAppointmentStatus(ctx.user.id, input);
	}
	@Mutation({ input: reassignLeadInput, output: idOutput })
	async reassignLead(
		@Ctx() ctx: AuthedTrpcContext,
		@Input() input: z.infer<typeof reassignLeadInput>,
	) {
		return this.realEstateService.reassignLead(ctx.user.id, input);
	}
}
'''
open(p,"w").write(s)
EOF
sed -n 14,62p apps/api/src/real-estate/real-estate.router.ts | tr -d '\t' | tr '\n' ' '; echo; bunx biome check --write apps/api/src/real-estate 2>&1 | tail -2; cd apps/api && bunx tsc --noEmit -p tsconfig.json 2>&1 | tail -10; echo api $?