# Version Mapping

This file maps Flutter wrapper releases to the native SDK revisions they were validated against.

## `nuxie_flutter` `0.1.0`

- `nuxie-ios`: `06e5f3a`
- `nuxie-android`: `6f2a99b`
- Contract fixture package: `packages/mobile_wrapper_contract` (`0.1.0`)

## Policy

- Add a new entry for every wrapper release.
- Keep entries append-only.
- If native dependencies change without a wrapper version bump, record the change in the release notes and update this file in the same commit.
