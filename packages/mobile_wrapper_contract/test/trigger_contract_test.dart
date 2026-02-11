import 'dart:io';

import 'package:mobile_wrapper_contract/mobile_wrapper_contract.dart';
import 'package:test/test.dart';

void main() {
  test('terminal-state fixtures remain canonical', () {
    final fixturePath = 'fixtures/trigger_terminal_cases.json';
    final source = File(fixturePath).readAsStringSync();
    final fixtures = parseTriggerTerminalFixtures(source);

    for (final fixture in fixtures) {
      final actual = isTerminalTriggerUpdate(
        updateKind: fixture.updateKind,
        decisionKind: fixture.decisionKind,
        entitlementKind: fixture.entitlementKind,
      );
      expect(actual, fixture.expectedTerminal, reason: fixture.name);
    }
  });
}
