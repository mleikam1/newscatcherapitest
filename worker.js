const NEWS_API_BASE = "https://api.newscatcherapi.com/v3";
const US_COUNTRY = "US";

const FORBIDDEN_PARAMS = new Set(["location", "lat", "lon", "geo"]);

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

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json" },
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

function removeForbiddenParams(params) {
  for (const key of params.keys()) {
    if (FORBIDDEN_PARAMS.has(key)) {
      params.delete(key);
    }
  }
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

function filterUSArticles(articles) {
  if (!Array.isArray(articles)) return [];
  return articles.filter((article) => {
    const country = article?.country?.toString().toUpperCase();
    if (country === US_COUNTRY) return true;
    console.log(`Dropping non-US article: ${article?.link ?? "unknown"}`);
    return false;
  });
}

function withUsArticles(payload) {
  if (!payload || !Array.isArray(payload.articles)) return payload;
  return { ...payload, articles: filterUSArticles(payload.articles) };
}

function sanitizeParams(params) {
  const sanitized = {};
  for (const [key, value] of params.entries()) {
    if (FORBIDDEN_PARAMS.has(key)) continue;
    sanitized[key] = value;
  }
  return sanitized;
}

function logUpstreamFailure({ endpoint, params, status, body }) {
  console.log(
    JSON.stringify({
      message: "Upstream failure",
      endpoint,
      params,
      status,
      body,
    }),
  );
}

async function fetchNewsApi({ env, path, query, body }) {
  const token = env.NEWS_API_TOKEN;
  if (!token) {
    console.log("Missing API token env: NEWS_API_TOKEN");
    return jsonResponse(
      { error: "Missing NEWS_API_TOKEN in Cloudflare Worker environment." },
      500,
    );
  }

  const upstreamUrl = new URL(NEWS_API_BASE);
  upstreamUrl.pathname = path.startsWith("/")
    ? path
    : normalizeApiPath(path);

  const params = new URLSearchParams(query ?? undefined);
  removeForbiddenParams(params);
  upstreamUrl.search = params.toString();

  const headers = new Headers({
    "x-api-key": token,
    accept: "application/json",
    "content-type": "application/json",
  });

  const init = {
    method: body ? "POST" : "GET",
    headers,
  };
  if (body) {
    const sanitizedBody = { ...body };
    for (const key of Object.keys(sanitizedBody)) {
      if (FORBIDDEN_PARAMS.has(key)) {
        delete sanitizedBody[key];
      }
    }
    init.body = JSON.stringify(sanitizedBody);
  }

  console.log(`News API → ${init.method} ${upstreamUrl.toString()}`);
  const upstreamResponse = await fetch(upstreamUrl.toString(), init);
  console.log(
    `News API ← ${init.method} ${upstreamUrl.toString()} ${upstreamResponse.status}`,
  );

  if (upstreamResponse.status !== 200) {
    const upstreamBody = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: path,
      params: sanitizeParams(params),
      status: upstreamResponse.status,
      body: upstreamBody,
    });
    return jsonResponse(
      {
        articles: [],
        error: "Upstream unavailable",
      },
      200,
    );
  }

  try {
    const payload = await upstreamResponse.json();
    return jsonResponse(withUsArticles(payload), 200);
  } catch (error) {
    const bodyText = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: path,
      params: sanitizeParams(params),
      status: upstreamResponse.status,
      body: bodyText,
    });
    return jsonResponse(
      {
        articles: [],
        error: "Upstream unavailable",
      },
      200,
    );
  }
}

async function handleHealth(env) {
  const token = env.NEWS_API_TOKEN;
  if (!token) {
    return jsonResponse(
      { error: "Missing NEWS_API_TOKEN in Cloudflare Worker environment." },
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
    });
    return jsonResponse(
      {
        articles: [],
        error: "Upstream unavailable",
      },
      200,
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
    });
    return jsonResponse(
      {
        articles: [],
        error: "Upstream unavailable",
      },
      200,
    );
  }
}

async function handleLocalNews(request, env) {
  let payload = {};
  try {
    payload = await request.json();
  } catch (error) {
    console.log(`Local news payload parse error: ${error}`);
  }

  const q = buildLocalQuery({
    city: payload.city,
    state: payload.state,
  });

  const pageSize = Number(payload.page_size ?? payload.pageSize ?? 20);
  const page = Number(payload.page ?? 1);

  return fetchNewsApi({
    env,
    path: "/search",
    query: {
      q,
      lang: "en",
      page_size: String(Number.isFinite(pageSize) ? pageSize : 20),
      page: String(Number.isFinite(page) ? page : 1),
    },
  });
}

async function handleBreakingNews(request, env) {
  const primaryResponse = await fetchNewsApi({
    env,
    path: "/breaking-news",
  });

  const primaryPayload = await primaryResponse.clone().json();
  const articles = filterUSArticles(primaryPayload?.articles ?? []);
  if (articles.length > 0) {
    return primaryResponse;
  }

  console.log("Breaking news empty; falling back to search query.");
  return fetchNewsApi({
    env,
    path: "/search",
    query: {
      q: "breaking news",
      sort_by: "published_date",
      page_size: "10",
      lang: "en",
    },
  });
}

async function proxyRequest(request, env, { baseUrl, prefix }) {
  const url = new URL(request.url);
  const pathSuffix = url.pathname.slice(prefix.length);
  const upstreamUrl = new URL(baseUrl);
  upstreamUrl.pathname = normalizeApiPath(pathSuffix);

  const params = new URLSearchParams(url.search);
  removeForbiddenParams(params);
  upstreamUrl.search = params.toString();

  const token = env.NEWS_API_TOKEN;
  if (!token) {
    console.log("Missing API token env: NEWS_API_TOKEN");
    return jsonResponse(
      { error: "Missing NEWS_API_TOKEN in Cloudflare Worker environment." },
      500,
    );
  }

  const headers = new Headers(request.headers);
  headers.set("x-api-key", token);
  headers.delete("host");

  const init = {
    method: request.method,
    headers,
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
      for (const key of Object.keys(body)) {
        if (FORBIDDEN_PARAMS.has(key)) {
          delete body[key];
        }
      }
      init.body = JSON.stringify(body);
      headers.set("content-type", "application/json");
    } else {
      init.body = await request.arrayBuffer();
    }
  }

  console.log(`Proxy → ${request.method} ${upstreamUrl.toString()}`);
  const upstreamResponse = await fetch(upstreamUrl.toString(), init);
  console.log(
    `Proxy ← ${request.method} ${upstreamUrl.toString()} ${upstreamResponse.status}`,
  );

  if (upstreamResponse.status !== 200) {
    const upstreamBody = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: pathSuffix,
      params: sanitizeParams(params),
      status: upstreamResponse.status,
      body: upstreamBody,
    });
    return jsonResponse(
      {
        articles: [],
        error: "Upstream unavailable",
      },
      200,
    );
  }

  try {
    const payload = await upstreamResponse.json();
    return jsonResponse(withUsArticles(payload), 200);
  } catch (error) {
    const bodyText = await upstreamResponse.text();
    logUpstreamFailure({
      endpoint: pathSuffix,
      params: sanitizeParams(params),
      status: upstreamResponse.status,
      body: bodyText,
    });
    return jsonResponse(
      {
        articles: [],
        error: "Upstream unavailable",
      },
      200,
    );
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/news/__health") {
      return handleHealth(env);
    }

    if (url.pathname === "/local/local-news" && request.method === "POST") {
      return handleLocalNews(request, env);
    }

    if (url.pathname === "/news/breaking" && request.method === "GET") {
      return handleBreakingNews(request, env);
    }

    if (url.pathname.startsWith("/news/")) {
      return proxyRequest(request, env, {
        baseUrl: NEWS_API_BASE,
        prefix: "/news",
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
