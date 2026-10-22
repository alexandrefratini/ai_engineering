cd /home/user/endsi3g/fratex-agent/apps/api && cat > test/real-estate-tools.integration.spec.ts <<'EOF'
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { randomUUID } from "node:crypto";
import { db } from "@crm/db";
import { createLeadInput } from "../src/real-estate/real-estate.contracts";
import { AgentTriggerService } from "../src/agent/agent-trigger.service";
import { RealEstateService } from "../src/real-estate/real-estate.service";

const suffix = randomUUID();
const agency = `tools-agency-${suffix}`;
const owner = `tools-owner-${suffix}`;
const realtorUser = `tools-realtor-user-${suffix}`;
const marie = `tools-marie-${suffix}`;
const samuel = `tools-samuel-${suffix}`;
const trigger = new AgentTriggerService(db);
let pokes = 0;
trigger.poke = () => {
	pokes += 1;
};
const service = new RealEstateService(db, trigger);
const phone = `+1514${String(Math.floor(Math.random() * 9_000_000) + 1_000_000)}`;

beforeAll(async () => {
	await db.user.createMany({
		data: [owner, realtorUser].map((id) => ({
			id,
			name: id === owner ? "Alexandre" : "Marie",
			email: `${id}@example.test`,
		})),
	});
	await db.agency.create({ data: { id: agency, name: "Outils", slug: agency } });
	await db.client.createMany({
		data: [marie, samuel].map((id) => ({
			id,
			agencyId: agency,
			name: id === marie ? "Marie" : "Samuel",
			email: `${id}@example.test`,
			targetZones: ["Laval"],
		})),
	});
	await db.agencyUser.createMany({
		data: [
			{ agencyId: agency, userId: owner, role: "OWNER" },
			{ agencyId: agency, userId: realtorUser, role: "REALTOR", clientId: marie },
		],
	});
});

afterAll(async () => {
	await db.agentTask.deleteMany({ where: { agencyId: agency } });
	await db.agency.deleteMany({ where: { id: agency } });
	await db.user.deleteMany({ where: { id: { in: [owner, realtorUser] } } });
});

describe("realtor tools", () => {
	let leadId = "";

	it("normalizes the phone typed by the realtor", () => {
		const parsed = createLeadInput.parse({
			firstName: "Louis",
			phone: "(514) 555-0123",
			source: "REFERRAL",
			smsConsent: false,
			startAssistant: false,
		});
		expect(parsed.phone).toBe("+15145550123");
		expect(parsed.intent).toBe("UNKNOWN");
	});

	it("creates a manual lead with consent, a note and a queued first contact", async () => {
		const created = await service.createLead(owner, {
			agencyId: agency,
			clientId: marie,
			firstName: "Louis",
			lastName: "Bélanger",
			phone,
			source: "REFERRAL",
			intent: "BUY",
			note: "Référé par un ancien client, cherche un plex à Rosemont.",
			smsConsent: true,
			startAssistant: true,
		});
		expect(created.duplicate).toBe(false);
		expect(created.assistantQueued).toBe(true);
		expect(pokes).toBe(1);
		leadId = created.id ?? "";
		const lead = await db.lead.findUniqueOrThrow({ where: { id: leadId } });
		expect(lead.source).toBe("REFERRAL");
		expect(lead.consentSource).toBe(`manual:${owner}`);
		expect(lead.clientId).toBe(marie);
		expect(
			await db.agentTask.count({
				where: { agencyId: agency, kind: "real-estate-qualify", leadId },
			}),
		).toBe(1);
		const detail = await service.getLead(owner, { agencyId: agency, id: leadId });
		expect(detail.notes[0]?.body).toContain("plex à Rosemont");
		expect(detail.notes[0]?.authorName).toBe("Alexandre");
		expect(detail.lead.source).toBe("REFERRAL");
		expect(detail.canReassign).toBe(true);
	});

	it("never contacts a lead without consent and reports duplicates", async () => {
		const duplicate = await service.createLead(owner, {
			agencyId: agency,
			firstName: "Louis",
			phone,
			source: "INBOUND_CALL",
			intent: "UNKNOWN",
			smsConsent: true,
			startAssistant: true,
		});
		expect(duplicate).toEqual({ id: leadId, duplicate: true, assistantQueued: false });
		const silent = await service.createLead(owner, {
			agencyId: agency,
			firstName: "Nadia",
			phone: `${phone.slice(0, -1)}${(Number(phone.at(-1)) + 1) % 10}`,
			source: "SIGN",
			intent: "SELL",
			smsConsent: false,
			startAssistant: true,
		});
		expect(silent.assistantQueued).toBe(false);
		expect(
			await db.agentTask.count({ where: { leadId: silent.id ?? "" } }),
		).toBe(0);
	});

	it("scopes a realtor's lead to their own profile", async () => {
		const created = await service.createLead(realtorUser, {
			agencyId: agency,
			clientId: samuel,
			firstName: "Chloé",
			phone: `${phone.slice(0, -2)}99`,
			source: "OPEN_HOUSE",
			intent: "BUY",
			smsConsent: false,
			startAssistant: false,
		});
		const lead = await db.lead.findUniqueOrThrow({ where: { id: created.id ?? "" } });
		expect(lead.clientId).toBe(marie);
		const hidden = await service.createLead(realtorUser, {
			agencyId: agency,
			firstName: "Doublon",
			phone,
			source: "OTHER",
			intent: "UNKNOWN",
			smsConsent: false,
			startAssistant: false,
		});
		expect(hidden).toEqual({ id: leadId, duplicate: true, assistantQueued: false });
	});

	it("books a manual appointment and records its outcome", async () => {
		const appointment = await service.createAppointment(owner, {
			agencyId: agency,
			leadId,
			title: "Visite du plex",
			startTime: "2026-10-30T14:00:00-04:00",
			durationMinutes: 60,
			location: "4520, rue Saint-Denis",
		});
		let lead = await db.lead.findUniqueOrThrow({ where: { id: leadId } });
		expect(lead.status).toBe("APPOINTMENT_BOOKED");
		const stored = await db.appointment.findUniqueOrThrow({
			where: { id: appointment.id },
		});
		expect(stored.endTime.getTime() - stored.startTime.getTime()).toBe(3_600_000);
		expect(stored.description).toBe("4520, rue Saint-Denis");
		await service.updateAppointmentStatus(owner, {
			agencyId: agency,
			appointmentId: appointment.id,
			status: "NO_SHOW",
		});
		lead = await db.lead.findUniqueOrThrow({ where: { id: leadId } });
		expect(lead.status).toBe("QUALIFIED");
		const second = await service.createAppointment(owner, {
			agencyId: agency,
			leadId,
			title: "Visite reportée",
			startTime: "2026-11-02T10:00:00-05:00",
			durationMinutes: 45,
		});
		await service.updateAppointmentStatus(owner, {
			agencyId: agency,
			appointmentId: second.id,
			status: "COMPLETED",
		});
		lead = await db.lead.findUniqueOrThrow({ where: { id: leadId } });
		expect(lead.status).toBe("APPOINTMENT_HELD");
		const events = await db.attributionEvent.findMany({
			where: { leadId },
			select: { eventType: true },
		});
		expect(events.map((event) => event.eventType).sort()).toEqual([
			"APPOINTMENT_HELD",
			"APPOINTMENT_SCHEDULED",
			"APPOINTMENT_SCHEDULED",
			"LEAD_CREATED",
		]);
		expect(
			await db.agentTask.count({
				where: { agencyId: agency, kind: "real-estate-capi", leadId },
			}),
		).toBe(3);
	});

	it("lets staff reassign a lead, not realtors", async () => {
		await expect(
			service.reassignLead(realtorUser, {
				agencyId: agency,
				leadId,
				clientId: samuel,
			}),
		).rejects.toThrow();
		await service.reassignLead(owner, {
			agencyId: agency,
			leadId,
			clientId: samuel,
		});
		const lead = await db.lead.findUniqueOrThrow({ where: { id: leadId } });
		expect(lead.clientId).toBe(samuel);
		await expect(
			service.addNote(realtorUser, { agencyId: agency, leadId, body: "Pas à moi" }),
		).rejects.toThrow();
	});
});
EOF
bunx biome check --write test/real-estate-tools.integration.spec.ts >/dev/null 2>&1; CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts test/real-estate-tools.integration.spec.ts 2>&1 | tail -25