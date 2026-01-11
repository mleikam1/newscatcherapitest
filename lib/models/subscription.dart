class SubscriptionInfo {
  final Map<String, dynamic> raw;

  SubscriptionInfo(this.raw);

  String get plan => raw["plan"]?.toString() ?? raw["subscription"]?.toString() ?? "unknown";
  String get usage => raw["usage"]?.toString() ?? "unknown";
}
