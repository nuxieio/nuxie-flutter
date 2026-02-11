import 'package:mobile_wrapper_contract/mobile_wrapper_contract.dart';

class JourneyRef {
  const JourneyRef({
    required this.journeyId,
    required this.campaignId,
    this.flowId,
  });

  final String journeyId;
  final String campaignId;
  final String? flowId;
}

enum SuppressReason {
  alreadyActive,
  reentryLimited,
  holdout,
  noFlow,
  unknown,
}

sealed class TriggerDecision {
  const TriggerDecision(this.kind);

  final TriggerDecisionKind kind;
}

final class TriggerDecisionNoMatch extends TriggerDecision {
  const TriggerDecisionNoMatch() : super(TriggerDecisionKind.noMatch);
}

final class TriggerDecisionSuppressed extends TriggerDecision {
  const TriggerDecisionSuppressed(this.reason)
      : super(TriggerDecisionKind.suppressed);

  final SuppressReason reason;
}

final class TriggerDecisionJourneyStarted extends TriggerDecision {
  const TriggerDecisionJourneyStarted(this.ref)
      : super(TriggerDecisionKind.journeyStarted);

  final JourneyRef ref;
}

final class TriggerDecisionJourneyResumed extends TriggerDecision {
  const TriggerDecisionJourneyResumed(this.ref)
      : super(TriggerDecisionKind.journeyResumed);

  final JourneyRef ref;
}

final class TriggerDecisionFlowShown extends TriggerDecision {
  const TriggerDecisionFlowShown(this.ref)
      : super(TriggerDecisionKind.flowShown);

  final JourneyRef ref;
}

final class TriggerDecisionAllowedImmediate extends TriggerDecision {
  const TriggerDecisionAllowedImmediate()
      : super(TriggerDecisionKind.allowedImmediate);
}

final class TriggerDecisionDeniedImmediate extends TriggerDecision {
  const TriggerDecisionDeniedImmediate()
      : super(TriggerDecisionKind.deniedImmediate);
}

sealed class EntitlementUpdate {
  const EntitlementUpdate(this.kind);

  final EntitlementUpdateKind kind;
}

final class EntitlementPending extends EntitlementUpdate {
  const EntitlementPending() : super(EntitlementUpdateKind.pending);
}

final class EntitlementAllowed extends EntitlementUpdate {
  const EntitlementAllowed(this.source) : super(EntitlementUpdateKind.allowed);

  final GateSourceKind source;
}

final class EntitlementDenied extends EntitlementUpdate {
  const EntitlementDenied() : super(EntitlementUpdateKind.denied);
}

class JourneyUpdate {
  const JourneyUpdate({
    required this.journeyId,
    required this.campaignId,
    required this.exitReason,
    required this.goalMet,
    this.flowId,
    this.goalMetAtEpochMillis,
    this.durationSeconds,
    this.flowExitReason,
  });

  final String journeyId;
  final String campaignId;
  final String? flowId;
  final JourneyExitReasonKind exitReason;
  final bool goalMet;
  final int? goalMetAtEpochMillis;
  final double? durationSeconds;
  final String? flowExitReason;
}

class TriggerError {
  const TriggerError({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

sealed class TriggerUpdate {
  const TriggerUpdate();

  TriggerUpdateKind get kind;

  bool get isTerminal;
}

final class TriggerDecisionUpdate extends TriggerUpdate {
  const TriggerDecisionUpdate(this.decision);

  final TriggerDecision decision;

  @override
  TriggerUpdateKind get kind => TriggerUpdateKind.decision;

  @override
  bool get isTerminal => isTerminalTriggerUpdate(
        updateKind: kind,
        decisionKind: decision.kind,
      );
}

final class TriggerEntitlementUpdate extends TriggerUpdate {
  const TriggerEntitlementUpdate(this.entitlement);

  final EntitlementUpdate entitlement;

  @override
  TriggerUpdateKind get kind => TriggerUpdateKind.entitlement;

  @override
  bool get isTerminal => isTerminalTriggerUpdate(
        updateKind: kind,
        entitlementKind: entitlement.kind,
      );
}

final class TriggerJourneyUpdate extends TriggerUpdate {
  const TriggerJourneyUpdate(this.journey);

  final JourneyUpdate journey;

  @override
  TriggerUpdateKind get kind => TriggerUpdateKind.journey;

  @override
  bool get isTerminal => isTerminalTriggerUpdate(updateKind: kind);
}

final class TriggerErrorUpdate extends TriggerUpdate {
  const TriggerErrorUpdate(this.error);

  final TriggerError error;

  @override
  TriggerUpdateKind get kind => TriggerUpdateKind.error;

  @override
  bool get isTerminal => isTerminalTriggerUpdate(updateKind: kind);
}

typedef TriggerTerminalUpdate = TriggerUpdate;
