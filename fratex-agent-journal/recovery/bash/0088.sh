cd /home/user/endsi3g/fratex-agent/packages/ui/src/components/brand-logos && I=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad/icons/x/package/icons && python3 - "$I" <<'EOF'
import re,sys
I=sys.argv[1]
def path(n): return re.search(r' d="([^"]*)"', open(f"{I}/{n}.svg").read()).group(1)
def write(name, comp, body):
    open(f"{name}.tsx","w").write(f'''import type * as React from "react";

const {comp} = (props: React.SVGProps<SVGSVGElement>) => (
	<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" {{...props}}>
{body}
	</svg>
);

export default {comp};
''')
write("meta","MetaLogo",f'\t\t<path fill="#0467DF" d="{path("meta")}" />')
write("twilio","TwilioLogo",f'\t\t<path fill="#F22F46" d="{path("twilio")}" />')
g=path("googlegemini")
open("gemini.tsx","w").write(f'''import type * as React from "react";
import {{ useId }} from "react";

const GeminiLogo = (props: React.SVGProps<SVGSVGElement>) => {{
	const gradient = useId();
	return (
		<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" {{...props}}>
			<defs>
				<linearGradient id={{gradient}} x1="4" y1="20" x2="20" y2="4" gradientUnits="userSpaceOnUse">
					<stop stopColor="#1C7DFF" />
					<stop offset="0.52" stopColor="#1C69FF" />
					<stop offset="1" stopColor="#F0DCD6" />
				</linearGradient>
			</defs>
			<path fill={{`url(#${{gradient}})`}} d="{g}" />
		</svg>
	);
}};

export default GeminiLogo;
''')
c=path("googlecalendar")
parts={
 "right":"M18.316 5.684H24v12.632h-5.684V5.684z",
 "bottom":"M5.684 24h12.632v-5.684H5.684V24z",
 "frame":"M18.316 5.684V0H1.895A1.894 1.894 0 0 0 0 1.895v16.421h5.684V5.684h12.632z",
}
for v in parts.values(): assert v in c, v
three=c[c.index("m-7.207 6.25"):c.index("m2.093-1.931")]
one=c[c.index("m2.093-1.931"):c.index("M22.105 0")]
corner=c[c.index("M22.105 0"):c.index("m-3.289 23.5")]
fold=c[c.index("m-3.289 23.5"):c.index("M0 22.105")]
left=c[c.index("M0 22.105"):]
three="M11.109 11.934"+three[len("m-7.207 6.25"):]
one="M13.202 10.003"+one[len("m2.093-1.931"):]
fold="M18.816 23.5"+fold[len("m-3.289 23.5"):]
body="\n".join([
 f'\t\t<path fill="#FBBC04" d="{parts["right"]}" />',
 f'\t\t<path fill="#34A853" d="{parts["bottom"]}" />',
 f'\t\t<path fill="#4285F4" d="{parts["frame"]}" />',
 f'\t\t<path fill="#4285F4" d="{three}" />',
 f'\t\t<path fill="#4285F4" d="{one}" />',
 f'\t\t<path fill="#1967D2" d="{corner}" />',
 f'\t\t<path fill="#EA4335" d="{fold}" />',
 f'\t\t<path fill="#188038" d="{left}" />',
])
write("google-calendar","GoogleCalendarLogo",body)
print(three[:40]); print(one[:40]); print(fold[:40])
EOF
cd /home/user/endsi3g/fratex-agent && bunx biome check --write packages/ui/src/components/brand-logos >/dev/null 2>&1; head -12 packages/ui/src/components/brand-logos/google-calendar.tsx | cut -c1-120