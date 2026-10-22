cd /home/user/endsi3g/fratex-agent && head -12 packages/validation/test/parse.spec.ts && cat > packages/validation/test/phone.spec.ts <<'EOF'
import { describe, expect, it } from "bun:test";
import {
	northAmericanPhone,
	toNorthAmericanE164,
} from "../src/real-estate";

describe("toNorthAmericanE164", () => {
	it("normalizes the formats a realtor types", () => {
		expect(toNorthAmericanE164("5145550199")).toBe("+15145550199");
		expect(toNorthAmericanE164("(514) 555-0199")).toBe("+15145550199");
		expect(toNorthAmericanE164("514 555 0199")).toBe("+15145550199");
		expect(toNorthAmericanE164("1-514-555-0199")).toBe("+15145550199");
		expect(toNorthAmericanE164("+1 514 555 0199")).toBe("+15145550199");
	});

	it("rejects numbers that are not ten North American digits", () => {
		expect(toNorthAmericanE164("555-0199")).toBeNull();
		expect(toNorthAmericanE164("+33 1 23 45 67 89")).toBeNull();
		expect(toNorthAmericanE164("")).toBeNull();
	});
});

describe("northAmericanPhone", () => {
	it("returns E.164 or a French error", () => {
		expect(northAmericanPhone.parse(" 514.555.0199 ")).toBe("+15145550199");
		const failed = northAmericanPhone.safeParse("123");
		expect(failed.success).toBe(false);
		expect(failed.error?.issues[0]?.message).toContain("10 chiffres");
	});
});
EOF
cd packages/validation && bun test 2>&1 | tail -5