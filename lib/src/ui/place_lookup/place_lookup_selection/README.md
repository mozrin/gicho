# PlaceLookupSelection

The value returned to a consumer when a place is chosen. By default, `fromPlace` replaces exact coordinates with the center of a stable approximate grid and omits the place ID and label. Set `precisionKm` to zero only when the application deliberately needs exact location. The public callback contract includes `accuracyRadiusKm` so consumers can present the result as approximate.
