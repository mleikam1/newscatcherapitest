class Article {
  final String? title;
  final String? excerpt;
  final String? summary;
  final String? link;
  final String? media;
  final String? publishedDate;
  final String? sourceName;
  final String? sourceUrl;
  final String? language;

  Article({
    required this.title,
    required this.excerpt,
    required this.summary,
    required this.link,
    required this.media,
    required this.publishedDate,
    required this.sourceName,
    required this.sourceUrl,
    required this.language,
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
    final excerpt = json["excerpt"]?.toString();
    final summary = json["summary"]?.toString();
    final link = json["link"]?.toString();
    final media = json["media"]?.toString();
    final publishedDate = json["published_date"]?.toString();
    final sourceName = (json["clean_url"] ?? json["source"] ?? json["source_name"])
        ?.toString();
    final sourceUrl = json["source_url"]?.toString();
    final language = json["language"]?.toString();

    return Article(
      title: title,
      excerpt: excerpt,
      summary: summary,
      link: link,
      media: media,
      publishedDate: publishedDate,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      language: language,
    );
  }
}
