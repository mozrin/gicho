# ContactPhoneField

Reusable phone entry with a country selector, formatting callback and explicit
owner-selected capabilities. A contact package supplies valid countries and
formatting; the consuming app supplies translated labels and verification state.
Checking SMS, WhatsApp or another option records the owner's declaration only.
`verified` is displayed only after the consuming service confirms a delivered
challenge to the number. Do not infer verification from formatting or choice.
