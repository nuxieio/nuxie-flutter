# Troubleshooting

## Native plugin is unavailable

Run `flutter clean`, resolve packages again, and rebuild the native app. Hot
reload cannot install a missing native plugin.

## An event produced no visible Experience

`trigger` is fire-and-forget and does not report a Journey decision. Inspect
`activities` and native logs. A normal no-match, a declined presentation while
another Journey owns the screen, and a load failure are distinct native facts.

## Feature data looks stale

Use `FeatureCheckPolicy.remote` for an authoritative check. The default
`cacheFirst` policy is intended for responsive UI.

## A purchase times out

Pass the purchase controller during `Nuxie.initialize`, complete every request,
and preserve the emitted request ID. Return one of the documented purchase or
restore variants.

## Generated bindings disagree

Regenerate all three Pigeon outputs from the checked-in schema and rerun
analysis and tests. Do not hand-edit generated files.
