import { createServer } from "node:http";
import { setTimeout } from "node:timers/promises";

const lake = {
  id: "8a99bb14-7873-4c0d-a398-5b1b3464ed30",
  nameVi: "Hồ Hoàn Kiếm",
  nameEn: "Hoan Kiem Lake",
  summaryEn: "A landmark in the heart of Hanoi.",
  imageUrl: "https://images.example.test/hoan-kiem.jpg",
  imageCredit: "Fixture photographer",
  address: "Hoàn Kiếm, Hà Nội",
};
const temple = {
  ...lake,
  id: "fb8bb849-97ee-45ea-a93c-40f0535c25b6",
  nameVi: "Văn Miếu",
  nameEn: "Temple of Literature",
  imageUrl: "https://images.example.test/van-mieu.jpg",
  address: "Đống Đa, Hà Nội",
};
const detail = {
  ...lake,
  historyEn: "A historic lake with a story of a returned sword.",
  cultureEn: "A meeting place for people across the city.",
  sourceUrl: "https://example.test/destination-source",
  openingHours: "Open all day",
  ticketPriceVnd: 30_000,
  ticketPriceUsd: "1.20",
  bookingInfo: "Buy tickets on site.",
  bestTimeToVisit: "Early morning",
  visitDurationMin: 60,
  latitude: 21.0287,
  longitude: 105.8522,
};
let recoveryRequests = 0;
let detailRecoveryRequests = 0;
let detailRequests = 0;
let defaultPageRequests = 0;

createServer(async (req, res) => {
  const url = new URL(req.url, "http://127.0.0.1");
  if (url.pathname === "/health") {
    res.end("ok");
    return;
  }
  if (url.pathname === "/default-page-requests") {
    res.end(String(defaultPageRequests));
    return;
  }
  if (url.pathname === "/detail-requests") {
    res.end(String(detailRequests));
    return;
  }
  if (req.method === "GET" && url.pathname.startsWith("/api/v1/destinations/")) {
    detailRequests++;
    const id = url.pathname.split("/").at(-1);
    res.setHeader("Content-Type", "application/json");
    if (id === lake.id) {
      await setTimeout(1500);
      res.end(JSON.stringify(detail));
    } else if (id === temple.id) {
      if (++detailRecoveryRequests === 1) {
        res.writeHead(503).end(JSON.stringify({ error: "Fixture is temporarily unavailable" }));
      } else {
        res.end(JSON.stringify({ ...detail, ...temple, sourceUrl: "javascript:alert(1)" }));
      }
    } else {
      res.writeHead(404).end(JSON.stringify({ error: "Fixture destination is absent" }));
    }
    return;
  }
  if (url.pathname !== "/api/v1/destinations" || req.method !== "GET") {
    res.writeHead(404).end();
    return;
  }

  const query = url.searchParams.get("q");
  const cursor = url.searchParams.get("cursor");
  if (!query && !cursor) defaultPageRequests++;
  if (query === "slow") await setTimeout(1500);
  if (query === "timeout") await setTimeout(7000);
  if (query === "retry" && ++recoveryRequests === 1) {
    res.writeHead(503, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Fixture is temporarily unavailable" }));
    return;
  }

  const items = query === "không có kết quả" ? [] : cursor === "page-two" ? [temple] : [lake];
  const nextCursor = query === "Hà Nội" && !cursor ? "page-two" : null;
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ items: query === "invalid-shape" ? "invalid" : items, nextCursor }));
}).listen(8182, "127.0.0.1");
