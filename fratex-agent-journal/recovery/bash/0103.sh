cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/components/connection-setup.tsx"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:60]
    s=s.replace(a,b)
rep('''		optional?: boolean;
		defaultValue?: string;
	}[];''','''		optional?: boolean;
		defaultValue?: string;
		description?: string;
		placeholder?: string;
	}[];''')
rep('''										<FieldLabel htmlFor={`setup-${field.name}`}>
											{field.label}
										</FieldLabel>''','''										<FieldLabel htmlFor={`setup-${field.name}`}>
											{field.label}
											{field.optional && (
												<span className="font-normal text-muted-foreground">
													{" "}
													(facultatif)
												</span>
											)}
										</FieldLabel>''')
rep('''											defaultValue={field.defaultValue}
											autoComplete={
												field.type === "password" ? "new-password" : "off"
											}
										/>''','''											defaultValue={field.defaultValue}
											placeholder={field.placeholder}
											autoComplete={
												field.type === "password" ? "new-password" : "off"
											}
										/>
										{field.description && (
											<FieldDescription>{field.description}</FieldDescription>
										)}''')
rep('''import { Field, FieldLabel, FieldGroup } from "./field";''','''import { Field, FieldDescription, FieldGroup, FieldLabel } from "./field";''')
open(p,"w").write(s)

D="apps/app/app/(app)/[slug]/settings/connections/"
p=D+"meta-ads-connection.tsx"
s=open(p).read()
rep('''import { useMutation } from "@tanstack/react-query";
import { useState } from "react";''','''import { useMutation, useQueryClient } from "@tanstack/react-query";
import { parseAsString, useQueryState } from "nuqs";''')
rep('''	const { scope, query, clients } = useSdrConnections();
	const [clientId, setClientId] = useState("");
	const mutation = useMutation(trpc.realEstate.configureMeta.mutationOptions());''','''	const cache = useQueryClient();
	const { scope, query, clients } = useSdrConnections();
	const [chosen, setChosen] = useQueryState("client", parseAsString);
	const mutation = useMutation(trpc.realEstate.configureMeta.mutationOptions());
	const realtors = clients.data?.clients ?? [];
	const clientId = realtors.some((client) => client.id === chosen)
		? (chosen ?? "")
		: (realtors.find((client) => !client.setup.metaForm)?.id ??
			realtors[0]?.id ??
			"");''')
rep('''						title="Meta Lead Ads"
						description={
							query.data.meta.webhookActive
								? "Un webhook signé est enregistré pour cette agence."
								: "Associez explicitement le formulaire au courtier. Aucun webhook reçu pour cette agence."
						}''','''						title="Relier un formulaire"
						description={
							query.data.meta.webhookActive
								? `${query.data.meta.formCount} formulaire${query.data.meta.formCount > 1 ? "s" : ""} relié${query.data.meta.formCount > 1 ? "s" : ""}. Meta a déjà envoyé des prospects signés à cette agence.`
								: "Tous les identifiants se trouvent dans Meta Business Suite. Aucun prospect n'est encore arrivé de Meta pour cette agence."
						}''')
rep('''						fields={[
							{ name: "metaAccountId", label: "ID du compte publicitaire" },
							{ name: "metaCampaignId", label: "ID de campagne" },
							{ name: "metaFormId", label: "ID du formulaire" },
							{ name: "accessToken", label: "Jeton Meta", type: "password" },
							{
								name: "pixelId",
								label: "ID du pixel CAPI facultatif",
								optional: true,
							},
						]}''','''						fields={[
							{
								name: "metaAccountId",
								label: "ID du compte publicitaire",
								placeholder: "act_123456789",
								description:
									"Gestionnaire de publicités → menu du compte, en haut à gauche.",
							},
							{
								name: "metaCampaignId",
								label: "ID de la campagne",
								description:
									"Gestionnaire de publicités → colonne « ID de la campagne ».",
							},
							{
								name: "metaFormId",
								label: "ID du formulaire instantané",
								description:
									"Page Facebook → Outils de publication → Formulaires instantanés.",
							},
							{
								name: "accessToken",
								label: "Jeton d'accès de la page",
								type: "password",
								description:
									"Utilisateur système de Business Manager, avec les droits leads_retrieval et pages_manage_ads.",
							},
							{
								name: "pixelId",
								label: "ID du pixel (Conversions API)",
								optional: true,
								description:
									"Renvoie à Meta les prospects qualifiés pour optimiser les publicités vers de vrais acheteurs.",
							},
						]}''')
rep('''							await query.refetch();
						}}
					>
						<WebhookAddress
							label="Webhook Meta"
							url={query.data.metaWebhookUrl}
						/>
						{clients.data && (
							<WorkspaceSelect
								label="Courtier destinataire"
								value={clientId}
								options={clients.data.clients}
								onChange={setClientId}
							/>
						)}''','''							await cache.invalidateQueries(trpc.realEstate.pathFilter());
						}}
					>
						{clients.data && (
							<WorkspaceSelect
								label="Courtier qui reçoit ces prospects"
								value={clientId}
								options={realtors}
								onChange={(id) => {
									void setChosen(id);
								}}
							/>
						)}
						<WebhookAddress
							label="Adresse de rappel (webhook) à coller dans l'application Meta"
							url={query.data.metaWebhookUrl}
						/>''')
open(p,"w").write(s)

p=D+"twilio-connection.tsx"
s=open(p).read()
rep('''						title="SMS Twilio"
						description={
							query.data.twilio.connected
								? "Identifiants enregistrés. Les accusés Twilio confirment la livraison."
								: "Enregistrez le compte et le numéro utilisés par cette agence."
						}''','''						title={
							query.data.twilio.phoneNumber
								? `Numéro actif : ${formatPhone(query.data.twilio.phoneNumber)}`
								: "Configurer le numéro de l'agence"
						}
						description={
							query.data.twilio.connected
								? "Identifiants enregistrés. Les accusés de livraison Twilio confirment chaque envoi. Enregistrez de nouveau pour changer de numéro."
								: "Les trois valeurs se trouvent dans la console Twilio, page d'accueil du compte."
						}''')
rep('''							{ name: "accountSid", label: "Account SID" },
							{ name: "authToken", label: "Auth Token", type: "password" },
							{ name: "phoneNumber", label: "Numéro au format +15145551234" },''','''							{
								name: "accountSid",
								label: "Account SID",
								placeholder: "AC…",
								description: "Console Twilio → Account Info.",
							},
							{
								name: "authToken",
								label: "Auth Token",
								type: "password",
								description: "Console Twilio → Account Info, bouton « Show ».",
							},
							{
								name: "phoneNumber",
								label: "Numéro SMS de l'agence",
								placeholder: "+15145551234",
								description:
									"Au format international. Le numéro doit être enregistré pour les SMS au Canada.",
							},''')
rep('''						<WebhookAddress
							label="Webhook SMS entrant"''','''						<WebhookAddress
							label="Adresse à coller dans Twilio → Phone Numbers → Messaging → « A message comes in »"''')
rep('''import { useMutation } from "@tanstack/react-query";''','''import { formatPhone } from "@crm/ui/lib/real-estate";
import { useMutation } from "@tanstack/react-query";''')
open(p,"w").write(s)
EOF
echo ok