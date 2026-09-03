# Testing

Run analysis and tests for every package:

```bash
for package in packages/nuxie_flutter_platform_interface \
  packages/nuxie_flutter_native \
  packages/nuxie_flutter \
  packages/nuxie_flutter/example \
  packages/nuxie_flutter_bloc \
  packages/nuxie_flutter_riverpod; do
  (cd "$package" && flutter analyze && flutter test)
done
```

Native release qualification also compiles the generated Kotlin host against
the pinned Android SDK and typechecks the generated Swift host against the
pinned iOS SDK. Mapper tests cover fractional Feature values, authoritative
usage state, typed activity/App Actions, and commerce result variants.
