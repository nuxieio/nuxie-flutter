# Architecture

The wrapper is deliberately thin:

1. `nuxie_flutter` owns Dart ergonomics and the singleton lifecycle.
2. `nuxie_flutter_platform_interface` defines portable scalar models.
3. `nuxie_flutter_native` sends those models through a generated Pigeon
   channel.
4. Swift and Kotlin translate directly to their native SDK counterparts.
5. Native SDKs own Journey state, presentation, profile synchronization,
   event persistence, Feature authority, and commerce execution.

No wrapper layer interprets Journey programs, calls Nuxie HTTP endpoints, or
maintains a second decision model. The generated channel is the compile-time
boundary: changing it regenerates Dart, Swift, and Kotlin together.

Public events are fire-and-forget. Observable output arrives through typed
Feature, activity, App Action, and commerce streams. App-owned purchase
controllers complete the same request ID emitted by native code, so completion
cannot drift from the original request.
