cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/components/realtor-onboarding-form.tsx"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:60]
    s=s.replace(a,b)
rep('export type OnboardingNextStep = { label: string; description: string; href: string };',
    'export type OnboardingNextStep = { label: string; description: string; href: string; done?: boolean };')
rep('''			<CardContent>
				<div className="grid gap-4 sm:grid-cols-2">{children}</div>
			</CardContent>''','''			<CardContent className="@container">
				<div className="grid gap-4 @md:grid-cols-2 @4xl:grid-cols-3">{children}</div>
			</CardContent>''')
rep('''	description,
	defaultValue,
}: {
	name: string;
	label: string;
	type?: string;
	optional?: boolean;
	placeholder?: string;
	description?: string;
	defaultValue?: string;
}) {''','''	description,
	defaultValue,
	pattern,
	title,
}: {
	name: string;
	label: string;
	type?: string;
	optional?: boolean;
	placeholder?: string;
	description?: string;
	defaultValue?: string;
	pattern?: string;
	title?: string;
}) {''')
rep('''				placeholder={placeholder}
				defaultValue={defaultValue}
			/>''','''				placeholder={placeholder}
				defaultValue={defaultValue}
				pattern={pattern}
				title={title}
			/>''')
rep('''export function RealtorOnboardingForm({
	onSubmitSuccess,
	defaults,
}: {
	onSubmitSuccess: (data: RealtorOnboardingData) => Promise<{ steps: OnboardingNextStep[] }>;
	defaults?: Partial<Pick<RealtorOnboardingData, "agency">>;
}) {''','''export function RealtorOnboardingForm({
	onSubmitSuccess,
	defaults,
	successActions,
}: {
	onSubmitSuccess: (data: RealtorOnboardingData) => Promise<{ steps: OnboardingNextStep[] }>;
	defaults?: Partial<Pick<RealtorOnboardingData, "agency">>;
	successActions?: ReactNode;
}) {''')
start=s.index("	if (steps)\n")
end=s.index("	return (\n		<form")
s=s[:start]+'''	if (steps) {
		const remaining = steps.filter((step) => !step.done).length;
		return (
			<Card className={REVEAL}>
				<CardHeader>
					<CardTitle>{name} est ajouté(e)</CardTitle>
					<CardDescription>
						{remaining === 0
							? "Le profil est enregistré et tout est déjà relié."
							: `Le profil est enregistré. Encore ${remaining} étape${remaining > 1 ? "s" : ""} pour que l'assistant reçoive et contacte ses prospects.`}
					</CardDescription>
				</CardHeader>
				<CardContent className="flex flex-col gap-4">
					<ol className="flex flex-col divide-y">
						{steps.map((step, index) => {
							const primary = !step.done && steps.findIndex((item) => !item.done) === index;
							return (
								<li
									key={step.href}
									className={cn("flex items-center gap-3 py-2.5 first:pt-0 last:pb-0", REVEAL)}
									style={staggerStyle(index)}
								>
									<span
										className={cn(
											"flex size-6 shrink-0 items-center justify-center rounded-full border text-xs tabular-nums",
											step.done && "border-primary bg-primary text-primary-foreground",
										)}
									>
										{step.done ? <Check aria-hidden="true" className="size-3.5" /> : index + 1}
									</span>
									<span className="flex min-w-0 flex-1 flex-col">
										<span className={cn("text-sm font-medium", step.done && "text-muted-foreground")}>
											{step.label}
										</span>
										<span className="text-xs text-muted-foreground">
											{step.done ? "Déjà en place pour l'agence." : step.description}
										</span>
									</span>
									<Button asChild variant={primary ? "default" : "outline"} size="sm">
										<a href={step.href}>{step.done ? "Voir" : "Ouvrir"}</a>
									</Button>
								</li>
							);
						})}
					</ol>
					{successActions && <div className="flex flex-wrap justify-end gap-2 border-t pt-4">{successActions}</div>}
				</CardContent>
			</Card>
		);
	}

'''+s[end:]
rep('''				<TextField name="phone" label="Téléphone" type="tel" optional placeholder="514 555-0100" />''','''				<TextField
					name="phone"
					label="Téléphone"
					type="tel"
					optional
					placeholder="514 555-0100"
					pattern="[\\\\d\\\\s().+\\\\-]{10,20}"
					title="Numéro nord-américain à 10 chiffres, par exemple 514 555-0100."
				/>''')
rep('''				<div className="sm:col-span-2">
					<TextField
						name="targetZones"''','''				<div className="col-span-full">
					<TextField
						name="targetZones"''')
rep('''				<fieldset className="flex flex-col gap-2 sm:col-span-2">''','''				<fieldset className="col-span-full flex flex-col gap-2">''')
rep('''				<div className="sm:col-span-2">
					<TextField
						name="calendarLink"''','''				<div className="@md:col-span-2 @4xl:col-span-1">
					<TextField
						name="calendarLink"''')
rep('import { type ReactNode, useState } from "react";','import { Check } from "lucide-react";\nimport { type ReactNode, useState } from "react";')
open(p,"w").write(s)
EOF
grep -n "lucide-react" packages/ui/package.json; grep -rn "from \"lucide-react\"" packages/ui/src/components | head -2; grep -n 'pattern=' packages/ui/src/components/realtor-onboarding-form.tsx