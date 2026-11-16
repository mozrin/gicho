# GichoBrand

Immutable resolved branding values. `fromConfiguration` reads the package-owned
`brand` object after the configuration service has validated and merged it.
`name` is required; `logoAsset` and `markAsset` are optional Flutter bundle
keys. Consumers use the public `GichoBrand` type and do not parse the brand
map themselves.
