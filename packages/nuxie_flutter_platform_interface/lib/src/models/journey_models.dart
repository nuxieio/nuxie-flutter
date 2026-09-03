class ExperienceRef {
  const ExperienceRef({
    required this.experienceId,
    this.experienceVersion,
    this.journeyId,
  });

  final String experienceId;
  final String? experienceVersion;
  final String? journeyId;
}

class AppAction {
  const AppAction({required this.name, required this.experience, this.payload});

  final String name;
  final Map<String, Object>? payload;
  final ExperienceRef experience;
}

class NuxieActivityInfo {
  const NuxieActivityInfo({
    required this.schemaVersion,
    required this.id,
    required this.timestampMs,
    required this.receivedAtMs,
    required this.name,
    required this.properties,
  });

  final int schemaVersion;
  final String id;
  final int timestampMs;
  final int receivedAtMs;
  final String name;
  final Map<String, Object> properties;
}
