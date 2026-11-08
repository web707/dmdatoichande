import "server-only";

import type { DestinationDetail, DestinationPage, DestinationSummary } from "./generated/destinations";

const requiredFields = ["id", "nameVi", "nameEn", "summaryEn", "imageUrl", "imageCredit", "address"] as const satisfies readonly (keyof DestinationSummary)[];

function isDestinationSummary(value: unknown): value is DestinationSummary {
  if (typeof value !== "object" || value === null) return false;
  const item = value as Record<string, unknown>;
  return requiredFields.every((key) => typeof item[key] === "string");
}

function isDestinationPage(value: unknown): value is DestinationPage {
  if (typeof value !== "object" || value === null) return false;
  const page = value as Record<string, unknown>;
  return Array.isArray(page.items) && page.items.every(isDestinationSummary)
    && (typeof page.nextCursor === "string" || page.nextCursor === null);
}

const detailTextFields = ["historyEn", "cultureEn", "sourceUrl", "openingHours", "ticketPriceUsd", "bookingInfo", "bestTimeToVisit"] as const satisfies readonly (keyof DestinationDetail)[];

function isDestinationDetail(value: unknown): value is DestinationDetail {
  if (!isDestinationSummary(value)) return false;
  const item: Partial<DestinationDetail> = value;
  return detailTextFields.every((key) => typeof item[key] === "string")
    && typeof item.latitude === "number" && Math.abs(item.latitude) <= 90
    && typeof item.longitude === "number" && Math.abs(item.longitude) <= 180
    && Number.isInteger(item.ticketPriceVnd) && Number.isInteger(item.visitDurationMin);
}

function catalogUrl(path = "") {
  return new URL(`/api/v1/destinations${path}`, process.env.HANOI_GUIDE_API_URL ?? "http://127.0.0.1:8090");
}

function fetchCatalog(url: URL, cacheDefaultPage = false) {
  return fetch(url, {
    headers: { Accept: "application/json" },
    redirect: "error",
    signal: AbortSignal.timeout(5_000),
    ...(cacheDefaultPage ? { next: { revalidate: 20 } } : { cache: "no-store" }),
  });
}

export async function getDestinations(query: string, cursor: string): Promise<DestinationPage> {
  const url = catalogUrl();
  url.searchParams.set("limit", "20");
  if (query) url.searchParams.set("q", query);
  if (cursor) url.searchParams.set("cursor", cursor);

  const response = await fetchCatalog(url, !query && !cursor);
  if (!response.ok) throw new Error(`Destination API returned ${response.status}`);
  const body: unknown = await response.json();
  if (!isDestinationPage(body)) throw new Error("Invalid destination page response");
  return body;
}

export async function getDestination(id: string): Promise<DestinationDetail | null> {
  if (!/^[\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12}$/i.test(id)) return null;

  const response = await fetchCatalog(catalogUrl(`/${id}`));
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`Destination API returned ${response.status}`);
  const body: unknown = await response.json();
  if (!isDestinationDetail(body) || body.id.toLowerCase() !== id.toLowerCase()) {
    throw new Error("Invalid destination detail response");
  }
  return body;
}
