cd /home/user/endsi3g/fratex-agent && cat > packages/ui/src/components/logo.tsx <<'EOF'
import type * as React from "react";

const Logo = (props: React.SVGProps<SVGSVGElement>) => (
	<svg
		xmlns="http://www.w3.org/2000/svg"
		width={512}
		height={512}
		viewBox="0 0 512 512"
		fill="none"
		aria-label="Fratex"
		{...props}
	>
		<path
			fillRule="evenodd"
			clipRule="evenodd"
			d="M112 0h288a112 112 0 0 1 112 112v288a112 112 0 0 1-112 112H112A112 112 0 0 1 0 400V112A112 112 0 0 1 112 0Zm48 120h200v68H232v38h88v64h-88v102h-72V120Z"
			fill="currentColor"
		/>
	</svg>
);
export default Logo;
EOF
S=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad; mkdir -p $S/brand && cat > $S/brand/icon.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><path fill-rule="evenodd" clip-rule="evenodd" d="M112 0h288a112 112 0 0 1 112 112v288a112 112 0 0 1-112 112H112A112 112 0 0 1 0 400V112A112 112 0 0 1 112 0Zm48 120h200v68H232v38h88v64h-88v102h-72V120Z" fill="#006B4F"/><path d="M160 120h200v68H232v38h88v64h-88v102h-72V120Z" fill="#fff"/></svg>
EOF
cd $S/brand && node -e '
const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs=require("fs");
(async()=>{const b=await chromium.launch({executablePath:"/opt/pw-browsers/chromium"});
const svg=fs.readFileSync("icon.svg","utf8");
for (const [n,s,pad] of [["favicon-96x96",96,0],["apple-touch-icon",180,0],["web-app-manifest-192x192",192,0],["web-app-manifest-512x512",512,0],["ico-32",32,0],["ico-16",16,0],["preview",160,0]]) {
 const p=await b.newPage({viewport:{width:s,height:s}});
 await p.setContent(`<html><body style="margin:0;background:transparent">${svg.replace("width=\"512\" height=\"512\"",`width="${s}" height="${s}"`)}</body></html>`);
 await p.screenshot({path:n+".png",omitBackground:true}); await p.close();}
await b.close();})()' && python3 - <<'EOF'
import struct
imgs=[open(f"ico-{s}.png","rb").read() for s in (16,32)]
header=struct.pack("<HHH",0,1,len(imgs))
offset=6+16*len(imgs); entries=b""; data=b""
for s,img in zip((16,32),imgs):
    entries+=struct.pack("<BBBBHHII",s,s,0,0,1,32,len(img),offset+len(data)); data+=img
open("favicon.ico","wb").write(header+entries+data)
print("ico ok")
EOF
ls -la $S/brand