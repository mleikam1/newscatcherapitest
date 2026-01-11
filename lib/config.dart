class AppConfig {
  // Recommended: Use your Cloudflare Worker.
  // Example: https://newscatcher-proxy.your-subdomain.workers.dev
  static const bool useProxy = true;
  static const String proxyBaseUrl = "newscatcherapitest.matt-leikam.workers.dev";

  // Direct calling (NOT recommended for production).
  static const String newsBaseUrl = "https://v3-api.newscatcherapi.com";
  static const String localBaseUrl = "https://local-news.newscatcherapi.com";

  // Only used if useProxy == false
  static const String newsApiToken = "sRY9TeCwpxkd9TsN8OnnSEWviqmXM-8F";
  static const String localApiToken = "47VspHTvb1zUwwtADp7tLJDGouFX5VLc";

  // Endpoint path prefixes when using proxy
  static const String proxyNewsPrefix = "/news";
  static const String proxyLocalPrefix = "/local";
}
