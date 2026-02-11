import 'dart:convert';

import 'trigger_contract.dart';

class TriggerTerminalFixture {
  const TriggerTerminalFixture({
    required this.name,
    required this.updateKind,
    required this.expectedTerminal,
    this.decisionKind,
    this.entitlementKind,
  });

  factory TriggerTerminalFixture.fromJson(Map<String, Object?> json) {
    return TriggerTerminalFixture(
      name: json['name']! as String,
      updateKind:
          TriggerUpdateKind.values.byName(json['updateKind']! as String),
      decisionKind: _decisionKindFromNullable(json['decisionKind']),
      entitlementKind: _entitlementKindFromNullable(json['entitlementKind']),
      expectedTerminal: json['expectedTerminal']! as bool,
    );
  }

  final String name;
  final TriggerUpdateKind updateKind;
  final TriggerDecisionKind? decisionKind;
  final EntitlementUpdateKind? entitlementKind;
  final bool expectedTerminal;

  static TriggerDecisionKind? _decisionKindFromNullable(Object? value) {
    if (value == null) return null;
    return TriggerDecisionKind.values.byName(value as String);
  }

  static EntitlementUpdateKind? _entitlementKindFromNullable(Object? value) {
    if (value == null) return null;
    return EntitlementUpdateKind.values.byName(value as String);
  }
}

List<TriggerTerminalFixture> parseTriggerTerminalFixtures(String jsonSource) {
  final decoded = json.decode(jsonSource) as List<Object?>;
  return decoded
      .map((entry) =>
          TriggerTerminalFixture.fromJson(entry! as Map<String, Object?>))
      .toList(growable: false);
}
