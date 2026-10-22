cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
import re
p="packages/validation/src/real-estate.ts"
s=open(p).read()
s=s.replace('''import { z } from "zod";
''','''import { z } from "zod";

const NORTH_AMERICAN_DIGITS = /^1?(\\d{10})$/;

export function toNorthAmericanE164(value: string): string | null {
	const match = NORTH_AMERICAN_DIGITS.exec(value.replace(/\\D/g, ""));
	return match ? `+1${match[1]}` : null;
}

export const northAmericanPhone = z
	.string()
	.trim()
	.transform((value, ctx) => {
		const phone = toNorthAmericanE164(value);
		if (phone) return phone;
		ctx.addIssue({
			code: "custom",
			message: "Numéro de téléphone nord-américain à 10 chiffres attendu.",
		});
		return z.NEVER;
	});
''',1)
open(p,"w").write(s)

p="apps/api/src/real-estate/real-estate.contracts.ts"
s=open(p).read()
s=s.replace('''	email: z.string().email(),
	phone: z.string().optional(),
	targetZones: z.array(z.string().trim().min(1)).min(1),
	brokerage: z.string().trim().min(1).max(120),''','''	email: z.string().email(),
	phone: northAmericanPhone.optional(),
	targetZones: z.array(z.string().trim().min(1)).min(1),
	brokerage: z.string().trim().min(1).max(120),''')
open(p,"w").write(s)
EOF
sed -n 1,8p apps/api/src/real-estate/real-estate.contracts.ts