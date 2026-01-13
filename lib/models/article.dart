class Article {
  final String? id;
  final String? title;
  final String? description;
  final String? excerpt;
  final String? summary;
  final String? fullText;
  final String? link;
  final String? media;
  final String? publishedDate;
  final String? updatedDate;
  final String? sourceName;
  final String? sourceUrl;
  final String? domainUrl;
  final String? language;
  final String? country;
  final bool isBreakingNews;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.excerpt,
    required this.summary,
    required this.fullText,
    required this.link,
    required this.media,
    required this.publishedDate,
    required this.updatedDate,
    required this.sourceName,
    required this.sourceUrl,
    required this.domainUrl,
    required this.language,
    required this.country,
    required this.isBreakingNews,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    // NewsCatcher fields are fairly consistent but can vary by endpoint.
    // Prefer:
    //  - title
    //  - excerpt OR summary
    //  - media (image)
    //  - link
    //  - published_date
    //  - clean_url / source name
    final title = json["title"]?.toString();
    final description = json["description"]?.toString();
    final excerpt = json["excerpt"]?.toString();
    final summary = json["summary"]?.toString();
    final fullText = json["full_text"]?.toString() ?? json["content"]?.toString();
    final link = json["link"]?.toString();
    final media = json["media"]?.toString();
    final publishedDate = json["published_date"]?.toString();
    final updatedDate = json["updated_date"]?.toString();
    final sourceName = (json["clean_url"] ?? json["source"] ?? json["source_name"])
        ?.toString();
    final sourceUrl = json["source_url"]?.toString();
    final domainUrl = json["domain_url"]?.toString();
    final language = json["language"]?.toString();
    final country = json["country"]?.toString();
    final id = json["article_id"]?.toString() ?? json["id"]?.toString();
    final isBreaking = json["is_breaking_news"] == true;

    return Article(
      id: id,
      title: title,
      description: description,
      excerpt: excerpt,
      summary: summary,
      fullText: fullText,
      link: link,
      media: media,
      publishedDate: publishedDate,
      updatedDate: updatedDate,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      domainUrl: domainUrl,
      language: language,
      country: country,
      isBreakingNews: isBreaking,
    );
  }

  Article copyWith({
    bool? isBreakingNews,
  }) {
    return Article(
      id: id,
      title: title,
      description: description,
      excerpt: excerpt,
      summary: summary,
      fullText: fullText,
      link: link,
      media: media,
      publishedDate: publishedDate,
      updatedDate: updatedDate,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      domainUrl: domainUrl,
      language: language,
      country: country,
      isBreakingNews: isBreakingNews ?? this.isBreakingNews,
    );
  }

  String cacheKey() {
    if (id != null && id!.trim().isNotEmpty) {
      return id!.trim();
    }
    final linkValue = link?.trim();
    if (linkValue != null && linkValue.isNotEmpty) {
      return linkValue;
    }
    return "${title ?? ""}-${publishedDate ?? ""}";
  }
}
