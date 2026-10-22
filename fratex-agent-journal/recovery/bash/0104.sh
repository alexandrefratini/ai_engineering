cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/settings/connections" && cat > gemini-connection.tsx <<'EOF'
"use client";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "@crm/ui/components/card";
import {
	RealEstateWorkspace,
	WorkspaceLoading,
	WorkspaceNotice,
} from "@crm/ui/components/real-estate-workspace";
import { cn } from "@crm/ui/lib/utils";
import { AgencyControl } from "../../real-estate/use-agency";
import { useSdrConnections } from "./use-sdr-connections";

export function GeminiConnection({ slug: _slug }: { slug: string }) {
	const { scope, query } = useSdrConnections();
	return (
		<RealEstateWorkspace>
			<AgencyControl scope={scope} />
			{scope.agencyId &&
				(query.isPending ? (
					<WorkspaceLoading />
				) : query.error ? (
					<WorkspaceNotice
						title="Modèle indisponible"
						error={query.error.message}
					/>
				) : (
					<Card>
						<CardHeader>
							<CardTitle className="flex items-center gap-2">
								<span
									aria-hidden="true"
									className={cn(
										"size-2 rounded-full",
										query.data.ai.configured
											? "bg-primary"
											: "bg-muted-foreground/40",
									)}
								/>
								{query.data.ai.configured
									? "L'assistant est prêt"
									: "L'assistant n'a pas de modèle"}
							</CardTitle>
							<CardDescription>
								{query.data.ai.configured
									? "Il qualifie chaque prospect par SMS à partir de ce que le prospect confirme, jamais à partir de suppositions."
									: "Le serveur n'a pas de clé pour le modèle. Les prospects reçoivent quand même le premier SMS, mais la qualification attend un humain."}
							</CardDescription>
						</CardHeader>
						<CardContent>
							<dl className="grid gap-x-6 gap-y-3 text-sm sm:grid-cols-[max-content_1fr]">
								<dt className="text-muted-foreground">Fournisseur</dt>
								<dd>{query.data.ai.provider}</dd>
								<dt className="text-muted-foreground">Modèle</dt>
								<dd className="font-mono text-xs">{query.data.ai.model}</dd>
								<dt className="text-muted-foreground">Où le changer</dt>
								<dd>
									{query.data.ai.provider === "AI Gateway"
										? "Variable AI_GATEWAY_API_KEY du serveur, et modèle dans Paramètres → Agents."
										: "Variables LLM_BASE_URL et LLM_MODEL du serveur."}
								</dd>
								<dt className="text-muted-foreground">Vérification</dt>
								<dd>
									La configuration indique ce qui est disponible. Le premier
									échange SMS qualifié confirme que tout fonctionne.
								</dd>
							</dl>
						</CardContent>
					</Card>
				))}
		</RealEstateWorkspace>
	);
}
EOF
cd /home/user/endsi3g/fratex-agent && bunx biome check --write "apps/app/app/(app)/[slug]/settings/connections" packages/ui/src/components/connection-setup.tsx packages/ui/src/components/calendar-connect-panel.tsx packages/ui/src/components/brand-logos 2>&1 | tail -3; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -8; echo app $?); (cd packages/ui && bunx tsc --noEmit 2>&1 | tail -5; echo ui $?)