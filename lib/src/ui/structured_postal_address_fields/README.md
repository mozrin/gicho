# StructuredPostalAddressFields

Renders the ordered, country-specific postal fields and required labels supplied
by a contact rules provider such as Contackage's Google libaddressinput adapter.
The caller owns country selection and draft controllers. Gicho owns only
the reusable Flutter presentation; it neither stores nor geocodes addresses.
