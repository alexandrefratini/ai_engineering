cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/api/src/real-estate/real-estate.service.ts"
s=open(p).read()
s=s.replace('''import {
	listingSuggestions,
	storedQualificationEvidence,
	workingHours,
} from "@crm/validation/real-estate";''','''import {
	googleAuthorizationResponse,
	listingSuggestions,
	storedQualificationEvidence,
	workingHours,
} from "@crm/validation/real-estate";''',1)
s=s.replace('''import { InjectDatabase } from "../database/database.constants";
''','''import { InjectDatabase } from "../database/database.constants";
import { readCalendarState, signCalendarState } from "./calendar-state";
''',1)
open(p,"w").write(s)
EOF
cat > apps/api/src/real-estate/real-estate-calendar.controller.ts <<'EOF'
import { Controller, Get, Query, Res } from "@nestjs/common";
import { ApiExcludeEndpoint, ApiTags } from "@nestjs/swagger";
import { AllowAnonymous } from "@thallesp/nestjs-better-auth";
import type { Response } from "express";
import { RealEstateService } from "./real-estate.service";
import { REAL_ESTATE } from "./real-estate-config";

@ApiTags("RealEstate")
@Controller("api/real-estate/calendar")
export class RealEstateCalendarController {
	constructor(private readonly realEstateService: RealEstateService) {}
	@Get("callback")
	@AllowAnonymous()
	@ApiExcludeEndpoint()
	async callback(
		@Query("code") code: string | undefined,
		@Query("state") state: string | undefined,
		@Query("error") error: string | undefined,
		@Res() res: Response,
	) {
		const result =
			error || !code || !state
				? { ok: false as const, reason: error ? "refused" : "expired" }
				: await this.realEstateService.completeCalendarConnection(code, state);
		const target = new URL(
			REAL_ESTATE.calendar.resultPath,
			process.env.APP_URL ?? "http://localhost:3000",
		);
		target.searchParams.set("statut", result.ok ? "ok" : result.reason);
		return res.redirect(302, target.toString());
	}
}
EOF
python3 - <<'EOF'
p="/home/user/endsi3g/fratex-agent/apps/api/src/real-estate/real-estate.module.ts"
s=open(p).read()
s=s.replace('''import { RealEstateRouter } from "./real-estate.router";''','''import { RealEstateRouter } from "./real-estate.router";
import { RealEstateCalendarController } from "./real-estate-calendar.controller";''')
s=s.replace('''	imports: [DatabaseModule, AgentModule],''','''	imports: [DatabaseModule, AgentModule],
	controllers: [RealEstateCalendarController],''')
open(p,"w").write(s)
EOF
bunx biome check --write apps/api/src/real-estate packages/validation/src 2>&1 | tail -2; cd apps/api && bunx tsc --noEmit -p tsconfig.json 2>&1 | tail -8; echo api $?