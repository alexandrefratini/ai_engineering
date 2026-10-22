cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/real-estate/leads/[leadId]" && python3 - <<'EOF'
p="lead-detail-view.tsx"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:70]
    s=s.replace(a,b,1)
rep('''	const exportCrm = useMutation(trpc.realEstate.syncDualCrm.mutationOptions());
''','''	const exportCrm = useMutation(trpc.realEstate.syncDualCrm.mutationOptions());
	const refresh = async () => {
		await detail.refetch();
		await cache.invalidateQueries(trpc.realEstate.pathFilter());
	};
	const addNote = useMutation(trpc.realEstate.addNote.mutationOptions());
	const createAppointment = useMutation(
		trpc.realEstate.createAppointment.mutationOptions(),
	);
	const outcome = useMutation(
		trpc.realEstate.updateAppointmentStatus.mutationOptions({
			onSuccess: refresh,
		}),
	);
	const reassign = useMutation(
		trpc.realEstate.reassignLead.mutationOptions({ onSuccess: refresh }),
	);
	const clients = useQuery(
		trpc.realEstate.clients.queryOptions(
			{ agencyId: scope.agencyId },
			{ enabled: Boolean(scope.agencyId && detail.data?.canReassign) },
		),
	);
''')
rep('''	const appointments = detail.data.appointments.map((appointment) => ({
		...appointment,
		startTime: new Date(appointment.startTime).toISOString(),
	}));''','''	const appointments = detail.data.appointments.map((appointment) => ({
		...appointment,
		startTime: new Date(appointment.startTime).toISOString(),
	}));
	const realtorOptions = [
		...(lead.clientId ? [] : [{ id: "", name: "Non assigné" }]),
		...(clients.data?.clients.map((client) => ({
			id: client.id,
			name: client.name,
		})) ?? []),
	];''')
rep('''					<>
						{detail.data.canWrite && (
							<WorkspaceSelect''','''					<>
						{detail.data.canReassign && clients.data && (
							<WorkspaceSelect
								compact
								label="Courtier"
								value={lead.clientId ?? ""}
								options={realtorOptions}
								onChange={(value) => {
									if (value && value !== lead.clientId)
										reassign.mutate({
											agencyId: lead.agencyId,
											leadId: lead.id,
											clientId: value,
										});
								}}
							/>
						)}
						{detail.data.canWrite && (
							<WorkspaceSelect''')
rep('''			{status.error && (
				<WorkspaceNotice
					title="Statut non modifié"
					error={status.error.message}
				/>
			)}''','''			{status.error && (
				<WorkspaceNotice
					title="Statut non modifié"
					error={status.error.message}
				/>
			)}
			{reassign.error && (
				<WorkspaceNotice
					title="Courtier non modifié"
					error={reassign.error.message}
				/>
			)}
			{outcome.error && (
				<WorkspaceNotice
					title="Rendez-vous non modifié"
					error={outcome.error.message}
				/>
			)}''')
rep('''			<LeadAppointments index={6} appointments={appointments} />''','''			<LeadAppointments
				index={6}
				appointments={appointments}
				canWrite={detail.data.canWrite}
				onCreate={async (appointment) => {
					await createAppointment.mutateAsync({
						agencyId: lead.agencyId,
						leadId: lead.id,
						...appointment,
					});
					await refresh();
				}}
				onOutcome={(appointmentId, next) => {
					outcome.mutate({
						agencyId: lead.agencyId,
						appointmentId,
						status: next,
					});
				}}
			/>
			<LeadNotes
				index={7}
				canWrite={detail.data.canWrite}
				notes={detail.data.notes.map((note) => ({
					...note,
					createdAt: new Date(note.createdAt).toISOString(),
				}))}
				onAdd={async (body) => {
					await addNote.mutateAsync({
						agencyId: lead.agencyId,
						leadId: lead.id,
						body,
					});
					await detail.refetch();
				}}
			/>''')
for a,b in [("index={7}\n\t\t\t\tmessages","index={8}\n\t\t\t\tmessages"),("<LeadSuggestedListings\n\t\t\t\tindex={8}","<LeadSuggestedListings\n\t\t\t\tindex={9}"),("<LeadFollowUp index={9}","<LeadFollowUp index={10}"),("<LeadHistory\n\t\t\t\tindex={10}","<LeadHistory\n\t\t\t\tindex={11}"),("index={11}\n\t\t\t\t\ttitle=\"Export CRM\"","index={12}\n\t\t\t\t\ttitle=\"Export CRM\"")]:
    if a in s: s=s.replace(a,b,1)
rep('''import { CrmExportForm } from "@crm/ui/components/crm-export-form";''','''import { CrmExportForm } from "@crm/ui/components/crm-export-form";
import { LeadNotes } from "@crm/ui/components/lead-tools";''')
open(p,"w").write(s)
EOF
grep -n "index={" lead-detail-view.tsx; bunx biome check --write lead-detail-view.tsx 2>&1 | tail -1; cd .. && bunx biome check --write leads-view.tsx new-lead-control.tsx page.tsx 2>&1 | tail -1; cd /home/user/endsi3g/fratex-agent/apps/app && bunx tsc --noEmit 2>&1 | tail -8; echo app $?