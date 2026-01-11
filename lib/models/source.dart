class Source {
  final String? name;
  final String? url;
  final String? country;
  final String? language;
  final String? rank;

  Source({
    required this.name,
    required this.url,
    required this.country,
    required this.language,
    required this.rank,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json["name"]?.toString(),
      url: (json["url"] ?? json["domain"])?.toString(),
      country: json["country"]?.toString(),
      language: json["language"]?.toString(),
      rank: (json["rank"] ?? json["global_rank"])?.toString(),
    );
  }
}
