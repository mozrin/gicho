# SplashScene

`SplashScene` renders consumer-owned splash art across phone portrait and
tablet/desktop landscape viewports. Pass both `portraitSceneAsset` and
`landscapeSceneAsset` for full-bleed scenes; it selects at 768 logical pixels
and center-crops with `BoxFit.cover`. Keep the principal subjects within each
image's central safe area. A single `artworkAsset` is an uncropped fallback.

The consumer owns asset files, config, wording, color choices, and optional
overlay content. Gicho owns the responsive image and layout behavior. The
construct does not start jobs or choose routes.
