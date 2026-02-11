# Migration Notes

## `0.1.0` (Initial Full SDK Release)

- Introduces federated package structure (`nuxie_flutter`, platform interface, native implementation).
- Introduces typed trigger operation API:
  - `trigger(...)` returns `NuxieTriggerOperation`
  - `triggerOnce(...)` provides terminal-only convenience behavior
- Introduces Dart purchase controller bridge:
  - `NuxiePurchaseController.onPurchase(...)`
  - `NuxiePurchaseController.onRestore(...)`
- Adds optional adapter packages:
  - `nuxie_flutter_riverpod`
  - `nuxie_flutter_bloc`
- Adds optional embedded native flow view:
  - `NuxieFlowView(flowId: ...)`

No backwards-compatibility guarantees exist for versions before `0.1.0`.
