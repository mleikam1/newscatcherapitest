class AppConfig {
  // Required: Use your Cloudflare Worker proxy base URL.
  // Example: https://newscatcher-proxy.your-subdomain.workers.dev
  static const String proxyBaseUrl = "https://newscatcherapitest.matt-leikam.workers.dev";

  // Endpoint path prefixes when using proxy
  static const String proxyNewsPrefix = "/news";
  static const String proxyLocalPrefix = "/local";
}
