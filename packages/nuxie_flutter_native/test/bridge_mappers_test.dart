import 'package:flutter_test/flutter_test.dart';
import 'package:nuxie_flutter_native/src/bridge_mappers.dart';
import 'package:nuxie_flutter_native/src/generated/nuxie_bridge.g.dart';
import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

void main() {
  group('bridge mappers', () {
    test('configure request maps options to bridge payload', () {
      final request = toConfigureRequest(
        apiKey: 'NX_TEST',
        wrapperVersion: '1.2.3',
        usingPurchaseController: true,
        options: const NuxieOptions(
          environment: NuxieEnvironment.staging,
          logLevel: NuxieLogLevel.info,
          eventLinkingPolicy: NuxieEventLinkingPolicy.keepSeparate,
          purchaseTimeoutSeconds: 42,
        ),
      );

      expect(request.apiKey, 'NX_TEST');
      expect(request.wrapperVersion, '1.2.3');
      expect(request.usingPurchaseController, isTrue);
      expect(request.environment, 'staging');
      expect(request.logLevel, 'info');
      expect(request.eventLinkingPolicy, 'keep_separate');
      expect(request.purchaseTimeoutSeconds, 42);
    });

    test('trigger update mapping keeps terminal semantics', () {
      final nonTerminal = fromTriggerUpdate(
        PTriggerUpdate(
          requestId: 't_1',
          updateKind: 'decision',
          payload: <String?, Object?>{
            'type': 'flow_shown',
            'ref': <String?, Object?>{
              'journeyId': 'j_1',
              'campaignId': 'c_1',
              'flowId': 'f_1',
            },
          },
          isTerminal: false,
          timestampMs: 1,
        ),
      );

      expect(nonTerminal.isTerminal, isFalse);
      expect(nonTerminal.update, isA<TriggerDecisionUpdate>());

      final terminal = fromTriggerUpdate(
        PTriggerUpdate(
          requestId: 't_1',
          updateKind: 'decision',
          payload: <String?, Object?>{'type': 'allowed_immediate'},
          timestampMs: 2,
        ),
      );

      expect(terminal.isTerminal, isTrue);
      expect(
        terminal.update,
        isA<TriggerDecisionUpdate>().having(
          (u) => u.decision,
          'decision',
          isA<TriggerDecisionAllowedImmediate>(),
        ),
      );
    });

    test('unknown trigger update kind maps to wrapper error update', () {
      final update = fromTriggerUpdate(
        PTriggerUpdate(
          requestId: 't_2',
          updateKind: 'unknown_kind',
          payload: const <String?, Object?>{},
          timestampMs: 3,
        ),
      );

      expect(update.update, isA<TriggerErrorUpdate>());
      expect(
        update.update,
        isA<TriggerErrorUpdate>().having(
          (u) => u.error.code,
          'code',
          'unknown_trigger_update',
        ),
      );
    });

    test('purchase and restore result mapping preserves enum variants', () {
      final purchase = toPurchaseResult(
        const NuxiePurchaseResult(
          type: NuxiePurchaseResultType.pending,
          productId: 'sku_1',
        ),
      );
      final restore = toRestoreResult(
        const NuxieRestoreResult(
          type: NuxieRestoreResultType.noPurchases,
        ),
      );

      expect(purchase.type, 'pending');
      expect(purchase.productId, 'sku_1');
      expect(restore.type, 'no_purchases');
    });

    test('feature access changed event requires target access payload', () {
      expect(
        () => fromFeatureAccessChangedEvent(
          PFeatureAccessChangedEvent(
            featureId: 'pro',
            from: PFeatureAccess(
              allowed: false,
              unlimited: false,
              balance: 0,
              type: 'boolean',
            ),
            to: null,
            timestampMs: 1,
          ),
        ),
        throwsA(
          isA<NuxieException>().having((e) => e.code, 'code', 'NATIVE_ERROR'),
        ),
      );
    });
  });
}
