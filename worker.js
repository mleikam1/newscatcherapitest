const NEWS_API_BASE = "https://v3-api.newscatcherapi.com/api";
const LOCAL_API_BASE = "https://local-news.newscatcherapi.com/api";

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

async function proxyRequest(request, env, { baseUrl, prefix, tokenEnvKey }) {
  const url = new URL(request.url);
  const token = env[tokenEnvKey];

  if (!token) {
    console.log(`Missing API token env: ${tokenEnvKey}`);
    return jsonResponse(
      {
        error: `Missing ${tokenEnvKey} in Cloudflare Worker environment.`,
      },
      500,
    );
  }

  const pathSuffix = url.pathname.slice(prefix.length);
  const upstreamUrl = new URL(baseUrl);
  upstreamUrl.pathname = normalizeApiPath(pathSuffix);
  upstreamUrl.search = url.search;

  const headers = new Headers(request.headers);
  headers.set("x-api-token", token);
  headers.delete("host");

  const init = {
    method: request.method,
    headers,
  };

  if (request.method !== "GET" && request.method !== "HEAD") {
    init.body = await request.arrayBuffer();
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

  return upstreamResponse;
}

async function handleHealth(request, env) {
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

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/news/__health") {
      return handleHealth(request, env);
    }

    if (url.pathname.startsWith("/news/")) {
      return proxyRequest(request, env, {
        baseUrl: NEWS_API_BASE,
        prefix: "/news",
        tokenEnvKey: "NEWS_API_TOKEN",
      });
    }

    if (url.pathname.startsWith("/local/")) {
      return proxyRequest(request, env, {
        baseUrl: LOCAL_API_BASE,
        prefix: "/local",
        tokenEnvKey: "LOCAL_API_TOKEN",
      });
    }

    return jsonResponse(
      {
        error: "Not found. Use /news/* or /local/*.",
      },
      404,
    );
  },
};
