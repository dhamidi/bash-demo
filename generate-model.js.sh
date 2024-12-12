#!/usr/bin/env ./model.sh

valid-types <<'>>'
string
ObjectId
Date
>>

model EmailMessage
field externalThreadId string
field threadId ObjectId
field rawBody string
with timestamps

model EmailThread
field externalThreadId string
field threadId ObjectId
field latestMessage EmailMessage
with timestamps
