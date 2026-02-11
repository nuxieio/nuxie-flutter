# Nuxie Flutter SDK

Flutter SDK for Nuxie, implemented as a native-first wrapper over the Nuxie iOS and Android SDKs.

This repository uses a federated package layout:

- `packages/nuxie_flutter`: app-facing API
- `packages/nuxie_flutter_platform_interface`: platform contract
- `packages/nuxie_flutter_native`: iOS/Android implementation
- `packages/nuxie_flutter_riverpod`: Riverpod adapters
- `packages/nuxie_flutter_bloc`: Bloc/Cubit adapters
- `packages/mobile_wrapper_contract`: shared mobile wrapper contract types/fixtures
