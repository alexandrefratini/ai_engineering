cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/db/prisma/schema.prisma"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:60]
    s=s.replace(a,b,1)
rep('''  sessions      Session[]
  accounts      Account[]''','''  sessions      Session[]
  accounts      Account[]
  leadNotes     LeadNote[]''')
rep('''  currentSituation      String?
  firstContactedAt      DateTime?''','''  currentSituation      String?
  source                String?
  firstContactedAt      DateTime?''')
rep('''  propertyInterest      PropertyInterest?
  attributions          AttributionEvent[]

  @@unique([id, agencyId])''','''  propertyInterest      PropertyInterest?
  attributions          AttributionEvent[]
  notes                 LeadNote[]

  @@unique([id, agencyId])''')
rep('''model PropertyInterest {''','''model LeadNote {
  id        String   @id @default(cuid())
  agencyId  String
  leadId    String
  authorId  String?
  body      String
  createdAt DateTime @default(now())
  lead      Lead     @relation(fields: [leadId, agencyId], references: [id, agencyId], onDelete: Cascade)
  author    User?    @relation(fields: [authorId], references: [id], onDelete: SetNull)

  @@index([leadId, createdAt])
  @@map("leadNote")
}

model PropertyInterest {''')
open(p,"w").write(s)
EOF
cd packages/db && set -a && . ../../.env && set +a && bunx prisma format >/dev/null 2>&1; bunx prisma migrate dev --create-only --name add_lead_notes_and_source 2>&1 | tail -5; ls prisma/migrations | tail -2