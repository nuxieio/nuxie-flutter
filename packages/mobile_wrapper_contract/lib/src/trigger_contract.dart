enum TriggerUpdateKind {
  decision,
  entitlement,
  journey,
  error,
}

enum TriggerDecisionKind {
  noMatch,
  suppressed,
  journeyStarted,
  journeyResumed,
  flowShown,
  allowedImmediate,
  deniedImmediate,
}

enum EntitlementUpdateKind {
  pending,
  allowed,
  denied,
}

enum GateSourceKind {
  cache,
  purchase,
  restore,
}

enum JourneyExitReasonKind {
  completed,
  goalMet,
  triggerUnmatched,
  expired,
  error,
  cancelled,
}

/// Canonical terminal-state rules that both Expo and Flutter wrappers must honor.
bool isTerminalTriggerUpdate({
  required TriggerUpdateKind updateKind,
  TriggerDecisionKind? decisionKind,
  EntitlementUpdateKind? entitlementKind,
}) {
  switch (updateKind) {
    case TriggerUpdateKind.error:
      return true;
    case TriggerUpdateKind.journey:
      return true;
    case TriggerUpdateKind.decision:
      switch (decisionKind) {
        case TriggerDecisionKind.allowedImmediate:
        case TriggerDecisionKind.deniedImmediate:
        case TriggerDecisionKind.noMatch:
        case TriggerDecisionKind.suppressed:
          return true;
        case TriggerDecisionKind.flowShown:
        case TriggerDecisionKind.journeyStarted:
        case TriggerDecisionKind.journeyResumed:
        case null:
          return false;
      }
    case TriggerUpdateKind.entitlement:
      switch (entitlementKind) {
        case EntitlementUpdateKind.allowed:
        case EntitlementUpdateKind.denied:
          return true;
        case EntitlementUpdateKind.pending:
        case null:
          return false;
      }
  }
}
