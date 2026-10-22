cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/components/realtor-onboarding-form.tsx"
s=open(p).read()
s=s.replace('pattern="[\\\\d\\\\s().+\\\\-]{10,20}"','pattern="[\\d\\s\\(\\)\\.\\+\\-]{10,20}"')
open(p,"w").write(s)
EOF
grep -n 'pattern="' packages/ui/src/components/realtor-onboarding-form.tsx; node -e 'new RegExp(String.raw`^(?:[\d\s\(\)\.\+\-]{10,20})$`, "v"); console.log("v ok", /^[\d\s\(\)\.\+\-]{10,20}$/v.test("(514) 555-0199"))'