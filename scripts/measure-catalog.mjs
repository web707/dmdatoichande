import { isDeepStrictEqual } from "node:util";

const baselineOrigin = process.argv[2] ?? "http://127.0.0.1:8092";
const modernOrigin = process.argv[3] ?? "http://127.0.0.1:8090";
const samples = 40;

async function read(origin, path, headers) {
  const response = await fetch(new URL(path, origin), {
    cache: headers ? "force-cache" : "default",
    headers,
    signal: AbortSignal.timeout(5000),
  });
  if (response.status !== 200 && response.status !== 304) {
    throw new Error(`${path} returned HTTP ${response.status}`);
  }
  const body = await response.text();
  return {
    status: response.status,
    bytes: Buffer.byteLength(body, "utf8"),
    data: body ? JSON.parse(body) : null,
    etag: response.headers.get("etag"),
  };
}

function statistics(times) {
  const sorted = times.toSorted((a, b) => a - b);
  const at = (p) => +sorted[Math.ceil(p * sorted.length) - 1].toFixed(2);
  return { p50Ms: at(0.5), p95Ms: at(0.95), p99Ms: at(0.99) };
}

const modernPath = "/api/v1/destinations";
const legacy = await read(baselineOrigin, "/api/places");
const modern = await read(modernOrigin, modernPath);
const legacyPage = legacy.data.slice(0, 20).map((place) => ({
  id: place.id,
  nameVi: place.name_vi,
  nameEn: place.name_en,
  summaryEn: place.summary_en,
  imageUrl: place.image_url,
  imageCredit: place.image_credit,
  address: place.address,
}));
if (!isDeepStrictEqual(legacyPage, modern.data.items)) {
  throw new Error("Legacy and v1 destination summary data differs");
}

const catalogs = ["/api/places", "/api/phrases", "/api/foods_restaurants", "/api/events"];
const times = { legacyList: [], legacyRefresh: [], modernList: [] };
let refreshBytes = 0;
for (let index = 0; index < samples + 5; index++) {
  const startList = performance.now();
  await read(baselineOrigin, "/api/places");
  const listMs = performance.now() - startList;

  const startModern = performance.now();
  await read(modernOrigin, modernPath);
  const modernMs = performance.now() - startModern;

  const startRefresh = performance.now();
  const snapshot = await Promise.all(catalogs.map((path) => read(baselineOrigin, path)));
  const refreshMs = performance.now() - startRefresh;

  if (index < 5) continue;
  times.legacyList.push(listMs);
  times.modernList.push(modernMs);
  times.legacyRefresh.push(refreshMs);
  refreshBytes += snapshot.reduce((sum, page) => sum + page.bytes, 0);
}

const conditional = modern.etag
  ? await read(modernOrigin, modernPath, { "If-None-Match": modern.etag })
  : null;
console.log(JSON.stringify({
  samples,
  matchingFirstPageRecords: modern.data.items.length,
  legacyList: { requests: 1, bodyBytes: legacy.bytes, ...statistics(times.legacyList) },
  legacyRefresh: { requests: catalogs.length, meanBodyBytes: refreshBytes / samples, ...statistics(times.legacyRefresh) },
  modernList: { requests: 1, bodyBytes: modern.bytes, ...statistics(times.modernList) },
  modernConditional: conditional && { status: conditional.status, bodyBytes: conditional.bytes },
}, null, 2));
