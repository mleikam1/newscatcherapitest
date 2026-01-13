const NEWS_API_BASE = "https://api.newscatcherapi.com/v3";
const US_COUNTRY = "US";
const DEFAULT_LANG = "en";
const MAX_LOG_BODY = 800;
const DEFAULT_PAGE_SIZE = 50;
const MIN_PAGE_SIZE = 50;
const MAX_PAGE_SIZE = 100;

const FORBIDDEN_PARAMS = new Set(["location", "lat", "lon", "geo"]);
const LOCAL_ALLOWED_PARAMS = new Set(["location", "lat", "lon"]);
const SEARCH_ALLOWED_PARAMS = new Set(["location", "lat", "lon", "geo"]);
const BASE_ALLOWED_PARAMS = new Set([
  "countries",
  "lang",
  "sort_by",
  "order",
  "page",
  "page_size",
]);
const SEARCH_EXTRA_PARAMS = new Set(["q"]);

const STATE_NAME_BY_CODE = {
  AL: "Alabama",
  AK: "Alaska",
  AZ: "Arizona",
  AR: "Arkansas",
  CA: "California",
  CO: "Colorado",
  CT: "Connecticut",
  DE: "Delaware",
  FL: "Florida",
  GA: "Georgia",
  HI: "Hawaii",
  ID: "Idaho",
  IL: "Illinois",
  IN: "Indiana",
  IA: "Iowa",
  KS: "Kansas",
  KY: "Kentucky",
  LA: "Louisiana",
  ME: "Maine",
  MD: "Maryland",
  MA: "Massachusetts",
  MI: "Michigan",
  MN: "Minnesota",
  MS: "Mississippi",
  MO: "Missouri",
  MT: "Montana",
  NE: "Nebraska",
  NV: "Nevada",
  NH: "New Hampshire",
  NJ: "New Jersey",
  NM: "New Mexico",
  NY: "New York",
  NC: "North Carolina",
  ND: "North Dakota",
  OH: "Ohio",
  OK: "Oklahoma",
  OR: "Oregon",
  PA: "Pennsylvania",
  RI: "Rhode Island",
  SC: "South Carolina",
  SD: "South Dakota",
  TN: "Tennessee",
  TX: "Texas",
  UT: "Utah",
  VT: "Vermont",
  VA: "Virginia",
  WA: "Washington",
  WV: "West Virginia",
  WI: "Wisconsin",
  WY: "Wyoming",
  DC: "District of Columbia",
};

function jsonResponse(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json",
      "cache-control": "no-store",
      ...headers,
    },
  });
}

function normalizeApiPath(path) {
  let normalized = path.startsWith("/") ? path : `/${path}`;
  if (normalized.startsWith("/api/")) {
    normalized = normalized.slice(4);
  } else if (normalized === "/api") {
    normalized = "";
  }
  return normalized;
}

function removeForbiddenParams(params, allowedParams = new Set()) {
  for (const key of params.keys()) {
    if (FORBIDDEN_PARAMS.has(key) && !allowedParams.has(key)) {
      params.delete(key);
    }
  }
}

function filterParamsToAllowlist(params, allowlist) {
  for (const key of params.keys()) {
    if (!allowlist.has(key)) {
      params.delete(key);
    }
  }
}

function filterBodyToAllowlist(body, allowlist) {
  if (!body) return;
  for (const key of Object.keys(body)) {
    if (!allowlist.has(key)) {
      delete body[key];
    }
  }
}

function truncateBody(body) {
  if (!body) return "";
  if (body.length <= MAX_LOG_BODY) return body;
  return body.slice(0, MAX_LOG_BODY);
}

function clampPageSize(value) {
  if (!Number.isFinite(value)) return DEFAULT_PAGE_SIZE;
  if (value < MIN_PAGE_SIZE) return MIN_PAGE_SIZE;
  return Math.min(value, MAX_PAGE_SIZE);
}

function parseNumber(value) {
  if (value === null || value === undefined || value === "") return NaN;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : NaN;
}

function ensurePageParams(params) {
  const requestedPageSize = parseNumber(params.get("page_size"));
  const pageSize = clampPageSize(requestedPageSize);
  const requestedPage = parseNumber(params.get("page"));
  const page = Number.isFinite(requestedPage) && requestedPage > 0 ? requestedPage : 1;
  params.set("page_size", String(pageSize));
  params.set("page", String(page));
  return { page, pageSize };
}

function ensureBodyPageParams(body) {
  const requestedPageSize = parseNumber(body.page_size ?? body.pageSize);
  const pageSize = clampPageSize(requestedPageSize);
  const requestedPage = parseNumber(body.page ?? body.pageNumber);
  const page = Number.isFinite(requestedPage) && requestedPage > 0 ? requestedPage : 1;
  body.page_size = pageSize;
  body.page = page;
  return { page, pageSize };
}

function ensureSortParams(params) {
  if (!params.has("sort_by")) {
    params.set("sort_by", "published_date");
  }
  if (!params.has("order")) {
    params.set("order", "desc");
  }
}

function ensureBodySortParams(body) {
  if (!body.sort_by) {
    body.sort_by = "published_date";
  }
  if (!body.order) {
    body.order = "desc";
  }
}

function buildDebugHeaders({ requestId, routeName, params, page, pageSize }) {
  const headers = {
    "x-news-request-id": requestId ?? "n/a",
    "x-news-route": routeName ?? "unknown",
  };
  if (params) {
    try {
      headers["x-news-effective-query"] = JSON.stringify(params).slice(0, 1800);
    } catch (error) {
      headers["x-news-effective-query"] = "unavailable";
    }
  }
  if (page) headers["x-news-page"] = String(page);
  if (pageSize) headers["x-news-page-size"] = String(pageSize);
  return headers;
}

function extractDebugHeaders(response) {
  const headers = {};
  for (const [key, value] of response.headers.entries()) {
    if (key.startsWith("x-news-")) {
      headers[key] = value;
    }
  }
  return headers;
}

function getRequestId(request) {
  return (
    request.headers.get("cf-ray") ||
    request.headers.get("x-request-id") ||
    crypto.randomUUID()
  );
}

function normalizeLanguage(raw) {
  if (!raw) return DEFAULT_LANG;
  const trimmed = raw.toString().trim();
  if (!trimmed) return DEFAULT_LANG;
  return trimmed.toLowerCase();
}

function parseCsv(raw) {
  if (!raw) return [];
  return raw
    .toString()
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
}

function getRequestedCountries({ query, body }) {
  const raw =
    (query && query.get("countries")) ||
    (body && body.countries) ||
    (query && query.get("country")) ||
    null;
  const values = parseCsv(raw ?? "");
  return values.map((value) => value.toUpperCase());
}

function getSelectedLanguage({ query, body }) {
  const raw =
    (query && (query.get("lang") || query.get("language") || query.get("languages"))) ||
    (body && (body.lang || body.language || body.languages));
  const values = parseCsv(raw ?? "");
  if (values.length > 0) {
    return normalizeLanguage(values[0]);
  }
  return DEFAULT_LANG;
}

function normalizeState(state) {
  if (!state) return null;
  const trimmed = state.trim();
  if (!trimmed) return null;
  const upper = trimmed.toUpperCase();
  return STATE_NAME_BY_CODE[upper] ?? trimmed;
}

function buildLocalQuery({ city, state }) {
  const trimmedCity = city?.trim();
  const normalizedState = normalizeState(state);
  if (trimmedCity && normalizedState) {
    return `"${trimmedCity}" OR "${normalizedState}"`;
  }
  if (trimmedCity) return `"${trimmedCity}"`;
  if (normalizedState) return `"${normalizedState}" local news`;
  return "local news";
}

async function ensureEmptyReason(response, reason) {
  if (response.status !== 200) return response;
  try {
    const payload = await response.clone().json();
    if (Array.isArray(payload?.articles) && payload.articles.length === 0) {
      return jsonResponse({ ...payload, reason }, 200);
    }
  } catch (error) {
    console.log(`Empty reason parse error: ${error}`);
  }
  return response;
}

function filterArticles(articles, { countries = [], lang } = {}) {
  if (!Array.isArray(articles)) return [];
  const normalizedLang = lang ? normalizeLanguage(lang) : null;
  const hasCountryFilter = countries.length > 0;
  return articles.filter((article) => {
    if (hasCountryFilter) {
      const country = article?.country?.toString().toUpperCase();
      if (!countries.includes(country)) {
        console.log(`Dropping non-country article: ${article?.link ?? "unknown"}`);
        return false;
      }
    }
    if (normalizedLang) {
      const articleLang = article?.language?.toString().toLowerCase();
      if (!articleLang || articleLang !== normalizedLang) {
        console.log(`Dropping non-language article: ${article?.link ?? "unknown"}`);
        return false;
      }
    }
    return true;
  });
}

function withFilteredArticles(payload, filterOptions) {
  if (!payload || !Array.isArray(payload.articles)) return payload;
  return { ...payload, articles: filterArticles(payload.articles, filterOptions) };
}

function sanitizeParams(params, allowedParams = new Set()) {
  const sanitized = {};
  for (const [key, value] of params.entries()) {
    if (FORBIDDEN_PARAMS.has(key) && !allowedParams.has(key)) continue;
    sanitized[key] = value;
  }
  return sanitized;
}

function logUpstreamFailure({
  endpoint,
  params,
  status,
  body,
  requestId,
  routeName,
  upstreamUrl,
}) {
  console.log(
    JSON.stringify({
      message: "Upstream failure",
      routeName,
      requestId,
      endpoint,
      upstreamUrl,
      params,
      status,
      body: truncateBody(body),
    }),
  );
}

async function withErrorHandling({ request, routeName, handler }) {
  const requestId = getRequestId(request);
  try {
    return await handler(requestId);
  } catch (error) {
    console.log(
      JSON.stringify({
        message: "Route handler error",
        routeName,
        requestId,
        error: error?.toString?.() ?? String(error),
      }),
    );
    return jsonResponse(
      {
        status_code: 500,
        status: "Internal Server Error",
        message: "Unexpected server error.",
        request_id: requestId,
      },
      500,
    );
  }
}

async function fetchNewsApi({
  env,
  path,
  query,
  body,
  requestId,
  routeName,
  allowedParams,
  filterOptions,
  defaults,
}) {
  const token = env.NEWS_API_TOKEN;
  if (!token) {
    console.log("Missing API token env: NEWS_API_TOKEN");
    return jsonResponse(
      {
        status_code: 500,
        status: "Internal Server Error",
        message: "Missing NEWS_API_TOKEN in Cloudflare Worker environment.",
        request_id: requestId,
      },
      500,
    );
  }

  const upstreamUrl = new URL(NEWS_API_BASE);
  upstreamUrl.pathname = path.startsWith("/") ? path : normalizeApiPath(path);

  const params = new URLSearchParams(query ?? undefined);
  let page;
  let pageSize;
  let debugParams;
  if (!body) {
    if (defaults?.enforceSort) {
      ensureSortParams(params);
    }
    if (defaults?.enforcePagination) {
      const paging = ensurePageParams(params);
      page = paging.page;
      pageSize = paging.pageSize;
    }
  }
  removeForbiddenParams(params, allowedParams);
  upstreamUrl.search = params.toString();
  debugParams = sanitizeParams(params, allowedParams);

  const headers = new Headers({
    "x-api-key": token,
    accept: "application/json",
    "content-type": "application/json",
  });

  const init = {
    method: body ? "POST" : "GET",
    headers,
    cf: {
      cacheTtl: 0,
      cacheEverything: false,
    },
  };
  if (body) {
    const sanitizedBody = { ...body };
    let bodyPage;
    let bodyPageSize;
    if (defaults?.enforceSort) {
      ensureBodySortParams(sanitizedBody);
    }
    if (defaults?.enforcePagination) {
      const paging = ensureBodyPageParams(sanitizedBody);
      bodyPage = paging.page;
      bodyPageSize = paging.pageSize;
    }
    for (const key of Object.keys(sanitizedBody)) {
      if (FORBIDDEN_PARAMS.has(key) && !(allowedParams ?? new Set()).has(key)) {
        delete sanitizedBody[key];
      }
    }
    debugParams = sanitizedBody;
    if (!page && bodyPage) page = bodyPage;
    if (!pageSize && bodyPageSize) pageSize = bodyPageSize;
    init.body = JSON.stringify(sanitizedBody);
  }
  const debugHeaders = buildDebugHeaders({ requestId, routeName, params: debugParams, page, pageSize });

  console.log(
    `News API → ${init.method} ${upstreamUrl.toString()} (route=${routeName ?? path}, request=${requestId ?? "n/a"})`,
  );
  let upstreamResponse;
  try {
    upstreamResponse = await fetch(upstreamUrl.toString(), init);
  } catch (error) {
    console.log(
      `News API fetch error (route=${routeName ?? path}, request=${requestId ?? "n/a"}): ${error}`,
    );
    return jsonResponse(
      {
        status_code: 502,
        status: "Bad Gateway",
        message: "Upstream fetch failed.",
        request_id: requestId,
      },
      502,
    );
  }

  console.log(
    `News API ← ${init.method} ${upstreamUrl.toString()} ${upstreamResponse.status}`,
  );

  if (upstreamResponse.status !== 200) {
    const upstreamBody = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: path,
      params: sanitizeParams(params, allowedParams),
      status: upstreamResponse.status,
      body: upstreamBody,
      requestId,
      routeName,
      upstreamUrl: upstreamUrl.toString(),
    });
    return jsonResponse(
      {
        status_code: upstreamResponse.status,
        status: upstreamResponse.statusText || "Upstream Error",
        message: truncateBody(upstreamBody) || "Upstream unavailable",
        request_id: requestId,
      },
      upstreamResponse.status,
      debugHeaders,
    );
  }

  try {
    const payload = await upstreamResponse.json();
    return jsonResponse(withFilteredArticles(payload, filterOptions), 200, debugHeaders);
  } catch (error) {
    const bodyText = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: path,
      params: sanitizeParams(params, allowedParams),
      status: upstreamResponse.status,
      body: bodyText,
      requestId,
      routeName,
      upstreamUrl: upstreamUrl.toString(),
    });
    return jsonResponse(
      {
        status_code: 502,
        status: "Bad Gateway",
        message: "Upstream returned invalid JSON.",
        request_id: requestId,
      },
      502,
      debugHeaders,
    );
  }
}

async function handleHealth(request, env) {
  const token = env.NEWS_API_TOKEN;
  const requestId = getRequestId(request);
  if (!token) {
    return jsonResponse(
      {
        status_code: 500,
        status: "Internal Server Error",
        message: "Missing NEWS_API_TOKEN in Cloudflare Worker environment.",
        request_id: requestId,
      },
      500,
    );
  }

  const upstreamUrl = `${NEWS_API_BASE}/subscription`;
  console.log(`Health → GET ${upstreamUrl}`);

  const upstreamResponse = await fetch(upstreamUrl, {
    method: "GET",
    headers: {
      "x-api-key": token,
      accept: "application/json",
    },
  });

  console.log(`Health ← GET ${upstreamUrl} ${upstreamResponse.status}`);

  if (upstreamResponse.status !== 200) {
    const upstreamBody = await upstreamResponse.text();
    console.log(`Health upstream error body: ${upstreamBody}`);
    logUpstreamFailure({
      endpoint: "/subscription",
      params: {},
      status: upstreamResponse.status,
      body: upstreamBody,
      requestId,
      routeName: "news.__health",
      upstreamUrl,
    });
    return jsonResponse(
      {
        status_code: upstreamResponse.status,
        status: upstreamResponse.statusText || "Upstream Error",
        message: truncateBody(upstreamBody) || "Upstream unavailable",
        request_id: requestId,
      },
      upstreamResponse.status,
    );
  }

  try {
    const data = await upstreamResponse.json();
    return jsonResponse(data, 200);
  } catch (error) {
    const body = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: "/subscription",
      params: {},
      status: upstreamResponse.status,
      body,
      requestId,
      routeName: "news.__health",
      upstreamUrl,
    });
    return jsonResponse(
      {
        status_code: 502,
        status: "Bad Gateway",
        message: "Upstream returned invalid JSON.",
        request_id: requestId,
      },
      502,
    );
  }
}

async function handleLocalNews(request, env) {
  const requestId = getRequestId(request);
  let payload = {};
  try {
    payload = await request.json();
  } catch (error) {
    console.log(`Local news payload parse error: ${error}`);
  }

  const pageSize = Number(payload.page_size ?? payload.pageSize ?? DEFAULT_PAGE_SIZE);
  const page = Number(payload.page ?? 1);
  const lang = getSelectedLanguage({ body: payload });

  const latitude = Number(payload.lat ?? payload.latitude);
  const longitude = Number(payload.lon ?? payload.longitude);
  const radiusKm = Number(payload.radius_km ?? payload.radiusKm ?? payload.radius ?? 50);

  if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
    const response = await fetchNewsApi({
      env,
      path: "/local-news",
      body: {
        lat: latitude,
        lon: longitude,
        radius: Number.isFinite(radiusKm) ? radiusKm : 50,
        lang,
        page_size: Number.isFinite(pageSize) ? clampPageSize(pageSize) : DEFAULT_PAGE_SIZE,
        page: Number.isFinite(page) ? page : 1,
      },
      requestId,
      routeName: "local.local_news",
      allowedParams: LOCAL_ALLOWED_PARAMS,
      filterOptions: {
        lang,
      },
      defaults: {
        enforcePagination: true,
        enforceSort: true,
      },
    });
    if (response.status === 200) {
      return ensureEmptyReason(response, "No local articles found near you.");
    }
    console.log(
      `Local news upstream failed; falling back to search (request=${requestId}).`,
    );
  }

  const q = buildLocalQuery({
    city: payload.city,
    state: payload.state,
  });

  const response = await fetchNewsApi({
    env,
    path: "/search",
    query: {
      q,
      countries: US_COUNTRY,
      lang,
      page_size: String(Number.isFinite(pageSize) ? clampPageSize(pageSize) : DEFAULT_PAGE_SIZE),
      page: String(Number.isFinite(page) ? page : 1),
    },
    requestId,
    routeName: "local.local_news.search",
    filterOptions: {
      lang,
      countries: [US_COUNTRY],
    },
    defaults: {
      enforcePagination: true,
      enforceSort: true,
    },
  });
  return ensureEmptyReason(response, "No local articles matched this location.");
}

async function handleBreakingNews(request, env) {
  const requestId = getRequestId(request);
  const url = new URL(request.url);
  const params = new URLSearchParams(url.search);
  const lang = getSelectedLanguage({ query: params });
  const countries = getRequestedCountries({ query: params });
  const filterOptions = {
    lang,
    countries: countries.length > 0 ? countries : [US_COUNTRY],
  };

  const primaryResponse = await fetchNewsApi({
    env,
    path: "/breaking",
    query: {
      countries: filterOptions.countries.join(","),
      lang,
    },
    requestId,
    routeName: "news.breaking",
    filterOptions,
    defaults: {
      enforcePagination: true,
      enforceSort: true,
    },
  });

  if (primaryResponse.status !== 200) {
    return primaryResponse;
  }

  let primaryPayload;
  try {
    primaryPayload = await primaryResponse.clone().json();
  } catch (error) {
    console.log(`Breaking news parse error: ${error}`);
  }
  const debugHeaders = extractDebugHeaders(primaryResponse);
  const now = Date.now();
  const articles = filterArticles(primaryPayload?.articles ?? [], filterOptions).filter(
    (article) => {
      if (!article?.is_breaking_news) return false;
      const published = Date.parse(article?.published_date ?? "");
      if (!Number.isFinite(published)) return false;
      const ageMs = now - published;
      return ageMs >= 0;
    },
  );
  if (articles.length === 0) {
    return jsonResponse(
      {
        ...primaryPayload,
        articles: [],
        reason: "No breaking stories right now.",
      },
      200,
      debugHeaders,
    );
  }

  return jsonResponse({ ...primaryPayload, articles }, 200, debugHeaders);
}

function normalizeSearchParams(params) {
  if (params.has("country") && !params.has("countries")) {
    params.set("countries", params.get("country"));
    params.delete("country");
  }
  if (params.has("language") && !params.has("lang")) {
    params.set("lang", params.get("language"));
    params.delete("language");
  }
}

async function proxyRequest(request, env, { baseUrl, prefix }) {
  const url = new URL(request.url);
  const requestId = getRequestId(request);
  const pathSuffix = url.pathname.slice(prefix.length);
  const upstreamUrl = new URL(baseUrl);
  upstreamUrl.pathname = normalizeApiPath(pathSuffix);

  const params = new URLSearchParams(url.search);
  let debugPaging;
  const allowedParams = pathSuffix === "/search" ? SEARCH_ALLOWED_PARAMS : undefined;
  const allowedQueryParams =
    pathSuffix === "/search"
      ? new Set([...BASE_ALLOWED_PARAMS, ...SEARCH_EXTRA_PARAMS])
      : BASE_ALLOWED_PARAMS;
  if (pathSuffix === "/search") {
    normalizeSearchParams(params);
    const q = params.get("q");
    if (!q || !q.trim()) {
      return jsonResponse(
        {
          status_code: 400,
          status: "Bad Request",
          message: "Query parameter 'q' is required.",
          request_id: requestId,
        },
        400,
      );
    }
  }
  filterParamsToAllowlist(params, allowedQueryParams);
  if (pathSuffix === "/search" || pathSuffix === "/latest_headlines") {
    ensureSortParams(params);
    debugPaging = ensurePageParams(params);
  }
  if (pathSuffix === "/breaking") {
    ensureSortParams(params);
    debugPaging = ensurePageParams(params);
  }
  removeForbiddenParams(params, allowedParams);
  upstreamUrl.search = params.toString();

  const token = env.NEWS_API_TOKEN;
  if (!token) {
    console.log("Missing API token env: NEWS_API_TOKEN");
    return jsonResponse(
      {
        status_code: 500,
        status: "Internal Server Error",
        message: "Missing NEWS_API_TOKEN in Cloudflare Worker environment.",
        request_id: requestId,
      },
      500,
    );
  }

  const headers = new Headers(request.headers);
  headers.set("x-api-key", token);
  headers.delete("host");

  const init = {
    method: request.method,
    headers,
    cf: {
      cacheTtl: 0,
      cacheEverything: false,
    },
  };

  let body;
  if (request.method !== "GET" && request.method !== "HEAD") {
    const contentType = headers.get("content-type") ?? "";
    if (contentType.includes("application/json")) {
      try {
        body = await request.json();
      } catch (error) {
        console.log(`Proxy JSON parse error: ${error}`);
      }
    }
    if (body) {
      filterBodyToAllowlist(body, allowedQueryParams);
      for (const key of Object.keys(body)) {
        if (FORBIDDEN_PARAMS.has(key) && !(allowedParams ?? new Set()).has(key)) {
          delete body[key];
        }
      }
      init.body = JSON.stringify(body);
      headers.set("content-type", "application/json");
    } else {
      init.body = await request.arrayBuffer();
    }
  }

  console.log(
    `Proxy → ${request.method} ${upstreamUrl.toString()} (request=${requestId})`,
  );
  let upstreamResponse;
  try {
    upstreamResponse = await fetch(upstreamUrl.toString(), init);
  } catch (error) {
    console.log(`Proxy fetch error (request=${requestId}): ${error}`);
    return jsonResponse(
      {
        status_code: 502,
        status: "Bad Gateway",
        message: "Upstream fetch failed.",
        request_id: requestId,
      },
      502,
    );
  }
  console.log(
    `Proxy ← ${request.method} ${upstreamUrl.toString()} ${upstreamResponse.status}`,
  );

  if (upstreamResponse.status !== 200) {
    const upstreamBody = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: pathSuffix,
      params: sanitizeParams(params, allowedParams),
      status: upstreamResponse.status,
      body: upstreamBody,
      requestId,
      routeName: "proxy",
      upstreamUrl: upstreamUrl.toString(),
    });
    return jsonResponse(
      {
        status_code: upstreamResponse.status,
        status: upstreamResponse.statusText || "Upstream Error",
        message: truncateBody(upstreamBody) || "Upstream unavailable",
        request_id: requestId,
      },
      upstreamResponse.status,
      buildDebugHeaders({
        requestId,
        routeName: "proxy",
        params: sanitizeParams(params, allowedParams),
        page: debugPaging?.page,
        pageSize: debugPaging?.pageSize,
      }),
    );
  }

  try {
    const payload = await upstreamResponse.json();
    const filterOptions = {
      lang: getSelectedLanguage({ query: params }),
      countries: getRequestedCountries({ query: params }),
    };
    return jsonResponse(
      withFilteredArticles(payload, filterOptions),
      200,
      buildDebugHeaders({
        requestId,
        routeName: "proxy",
        params: sanitizeParams(params, allowedParams),
        page: debugPaging?.page,
        pageSize: debugPaging?.pageSize,
      }),
    );
  } catch (error) {
    const bodyText = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: pathSuffix,
      params: sanitizeParams(params, allowedParams),
      status: upstreamResponse.status,
      body: bodyText,
      requestId,
      routeName: "proxy",
      upstreamUrl: upstreamUrl.toString(),
    });
    return jsonResponse(
      {
        status_code: 502,
        status: "Bad Gateway",
        message: "Upstream returned invalid JSON.",
        request_id: requestId,
      },
      502,
      buildDebugHeaders({
        requestId,
        routeName: "proxy",
        params: sanitizeParams(params, allowedParams),
        page: debugPaging?.page,
        pageSize: debugPaging?.pageSize,
      }),
    );
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/news/__health") {
      return withErrorHandling({
        request,
        routeName: "news.__health",
        handler: () => handleHealth(request, env),
      });
    }

    if (url.pathname === "/local/local-news" && request.method === "POST") {
      return withErrorHandling({
        request,
        routeName: "local.local_news",
        handler: () => handleLocalNews(request, env),
      });
    }

    if (url.pathname === "/news/breaking" && request.method === "GET") {
      return withErrorHandling({
        request,
        routeName: "news.breaking",
        handler: () => handleBreakingNews(request, env),
      });
    }

    if (url.pathname.startsWith("/news/")) {
      return withErrorHandling({
        request,
        routeName: "news.proxy",
        handler: () =>
          proxyRequest(request, env, {
            baseUrl: NEWS_API_BASE,
            prefix: "/news",
          }),
      });
    }

    return jsonResponse(
      {
        error: "Not found. Use /news/* or /local/local-news.",
      },
      404,
    );
  },
};
