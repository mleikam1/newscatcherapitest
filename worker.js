const NEWS_API_BASE = "https://v3-api.newscatcherapi.com/api";
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
  return `/api${normalized}`;
}

function removeForbiddenParams(params) {
  for (const key of params.keys()) {
    if (FORBIDDEN_PARAMS.has(key)) {
      params.delete(key);
    }
  }
}

function enforceUsCountry(params) {
  if (params.has("country")) {
    params.set("country", US_COUNTRY);
  }
  if (params.has("countries")) {
    params.set("countries", US_COUNTRY);
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
    return `${trimmedCity} OR ${normalizedState}`;
  }
  if (trimmedCity) return trimmedCity;
  if (normalizedState) return normalizedState;
  return "local news";
}

function filterUsArticles(payload) {
  if (!payload || !Array.isArray(payload.articles)) return payload;
  const kept = [];
  for (const article of payload.articles) {
    const country = article?.country?.toString().toUpperCase();
    if (country === US_COUNTRY) {
      kept.push(article);
    } else {
      console.log(`Dropping non-US article: ${article?.link ?? "unknown"}`);
    }
  }
  return { ...payload, articles: kept };
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
  upstreamUrl.pathname = normalizeApiPath(path);

  const params = new URLSearchParams(query ?? undefined);
  removeForbiddenParams(params);
  enforceUsCountry(params);
  upstreamUrl.search = params.toString();

  const headers = new Headers({
    "x-api-token": token,
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
    if (sanitizedBody.country) sanitizedBody.country = US_COUNTRY;
    if (sanitizedBody.countries) sanitizedBody.countries = US_COUNTRY;
    init.body = JSON.stringify(sanitizedBody);
  }

  console.log(`News API → ${init.method} ${upstreamUrl.toString()}`);
  const upstreamResponse = await fetch(upstreamUrl.toString(), init);
  console.log(
    `News API ← ${init.method} ${upstreamUrl.toString()} ${upstreamResponse.status}`,
  );

  if (upstreamResponse.status !== 200) {
    const upstreamBody = await upstreamResponse.text();
    console.log(`Upstream error body: ${upstreamBody}`);
    return jsonResponse(
      {
        upstream_status: upstreamResponse.status,
        upstream_body: upstreamBody,
        upstream_url: upstreamUrl.toString(),
      },
      upstreamResponse.status,
    );
  }

  try {
    const payload = await upstreamResponse.json();
    return jsonResponse(filterUsArticles(payload), 200);
  } catch (error) {
    const bodyText = await upstreamResponse.text();
    return jsonResponse(
      {
        error: `JSON parse error: ${error}`,
        upstream_body: bodyText,
        upstream_url: upstreamUrl.toString(),
      },
      500,
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
      "x-api-token": token,
      accept: "application/json",
    },
  });

  console.log(`Health ← GET ${upstreamUrl} ${upstreamResponse.status}`);

  if (upstreamResponse.status !== 200) {
    const upstreamBody = await upstreamResponse.text();
    console.log(`Health upstream error body: ${upstreamBody}`);
    return jsonResponse(
      {
        upstream_status: upstreamResponse.status,
        upstream_body: upstreamBody,
        upstream_url: upstreamUrl,
      },
      upstreamResponse.status,
    );
  }

  try {
    const data = await upstreamResponse.json();
    return jsonResponse(data, 200);
  } catch (error) {
    const body = await upstreamResponse.text();
    return jsonResponse(
      {
        error: `Health JSON parse error: ${error}`,
        upstream_body: body,
        upstream_url: upstreamUrl,
      },
      500,
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
      country: US_COUNTRY,
      lang: "en",
      page_size: String(Number.isFinite(pageSize) ? pageSize : 20),
      page: String(Number.isFinite(page) ? page : 1),
      sort_by: "relevancy",
    },
  });
}

async function handleBreakingNews(request, env) {
  const url = new URL(request.url);
  const pageSize = Number(url.searchParams.get("page_size") ?? 10);
  const page = Number(url.searchParams.get("page") ?? 1);

  const primaryResponse = await fetchNewsApi({
    env,
    path: "/latest_headlines",
    query: {
      topic: "breaking-news",
      country: US_COUNTRY,
      page_size: String(Number.isFinite(pageSize) ? pageSize : 10),
      page: String(Number.isFinite(page) ? page : 1),
    },
  });

  if (primaryResponse.status !== 200) {
    return primaryResponse;
  }

  const primaryPayload = await primaryResponse.clone().json();
  const articles = primaryPayload?.articles ?? [];
  if (Array.isArray(articles) && articles.length > 0) {
    return primaryResponse;
  }

  console.log("Breaking news empty; falling back to search query.");
  return fetchNewsApi({
    env,
    path: "/search",
    query: {
      q: "breaking news",
      country: US_COUNTRY,
      sort_by: "published_date",
      page_size: String(Number.isFinite(pageSize) ? pageSize : 10),
      page: String(Number.isFinite(page) ? page : 1),
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
  enforceUsCountry(params);
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
  headers.set("x-api-token", token);
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
      if (body.country) body.country = US_COUNTRY;
      if (body.countries) body.countries = US_COUNTRY;
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
    console.log(`Upstream error body: ${upstreamBody}`);
    return jsonResponse(
      {
        upstream_status: upstreamResponse.status,
        upstream_body: upstreamBody,
        upstream_url: upstreamUrl.toString(),
      },
      upstreamResponse.status,
    );
  }

  try {
    const payload = await upstreamResponse.json();
    return jsonResponse(filterUsArticles(payload), 200);
  } catch (error) {
    const bodyText = await upstreamResponse.text();
    return jsonResponse(
      {
        error: `JSON parse error: ${error}`,
        upstream_body: bodyText,
        upstream_url: upstreamUrl.toString(),
      },
      500,
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
