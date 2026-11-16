# Configured startup parts

`GichoStartupScheduledScene.dart` parses one consumer-configured date window
and checks whether it applies to a local calendar date. It remains private to
`GichoStartupConfiguration` because schedule parsing is part of that
construct's configuration contract, not a standalone date utility. Promote it
only if another public Gicho workflow needs the same schedule model.

`GichoStartupNetworkCountry.dart` reads a two-letter country code from a
configured same-origin Cloudflare trace path. It discards all other trace
fields and remains private because only scheduled startup art needs this
lookup. Promote it only if another Gicho feature has a separately reviewed
network-country contract.
