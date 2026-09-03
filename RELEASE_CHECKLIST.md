# Release checklist

- Regenerate and commit all Pigeon outputs.
- Run `flutter analyze` and `flutter test` in every workspace package and the
  example.
- Compile the Kotlin plugin against the exact Android release.
- Typecheck the Swift plugin against the exact iOS release with strict
  concurrency enabled.
- Confirm native dependency manifests remain pinned to the same release.
- Audit public code and docs for removed presentation, profile, queue, and
  trigger-result surfaces.
- Verify Feature balances remain fractional and usage includes
  `authoritativeAccess`.
- Verify typed activity, App Action, purchase, and restore fixtures.
