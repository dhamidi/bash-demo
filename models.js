#!/usr/bin/env ./model-generator.js
model("EmailMessage");
field("receivedAt", Types.Date);
field("subject", Types.String);
emit();
