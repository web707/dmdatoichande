import { expect, test } from "@playwright/test";
import type { DestinationDetail, DestinationPage } from "../src/services/generated/destinations";

test("renders the same destination identities and order as the real API", async ({ page, request }) => {
  const apiUrl = process.env.HANOI_GUIDE_REAL_API_URL!;
  const api = await request.get(new URL("/api/v1/destinations?limit=20", apiUrl).href);
  expect(api.ok()).toBe(true);
  const { items } = (await api.json()) as DestinationPage;
  expect(items.length).toBeGreaterThan(0);

  await page.route("https://**/*", (route) => route.abort());
  await page.goto("/destinations");
  const cards = page.locator("[data-destination-id]");
  await expect(cards).toHaveCount(items.length);
  expect(await cards.evaluateAll((elements) => elements.map((element) => element.getAttribute("data-destination-id")))).toEqual(items.map(({ id }) => id));
  await expect(cards.getByRole("heading")).toHaveText(items.map(({ nameVi }) => nameVi));

  const detail = await request.get(new URL(`/api/v1/destinations/${items[0].id}`, apiUrl).href);
  expect(detail.ok()).toBe(true);
  const item = (await detail.json()) as DestinationDetail;
  await cards.first().getByRole("link", { name: item.nameVi }).click();
  await expect(page.getByRole("heading", { level: 1, name: item.nameVi })).toBeVisible();
  await expect(page.getByText(item.historyEn, { exact: true })).toBeVisible();
  await expect(page.getByText(item.cultureEn, { exact: true })).toBeVisible();
  await expect(page.getByText(`${item.latitude.toFixed(6)}, ${item.longitude.toFixed(6)}`, { exact: true })).toBeVisible();
});

test("finds a real destination by an upper-case address without accents", async ({ page, request }) => {
  const apiUrl = process.env.HANOI_GUIDE_REAL_API_URL!;
  const api = await request.get(new URL("/api/v1/destinations?limit=20", apiUrl).href);
  expect(api.ok()).toBe(true);
  const { items } = (await api.json()) as DestinationPage;
  const item = items.find(({ address }) => /^\d/.test(address) && /\p{M}/u.test(address.normalize("NFD")));
  expect(item, "The integration catalog must include an accented street address starting with a house number").toBeDefined();
  const address = item!.address.split(",")[0];
  const search = address.normalize("NFD").replace(/\p{M}/gu, "").replace(/đ/gi, "d").toUpperCase();

  await page.route("https://**/*", (route) => route.abort());
  await page.goto("/destinations");
  await page.getByRole("searchbox", { name: "Tìm điểm đến" }).fill(search);
  await page.getByRole("button", { name: "Tìm kiếm" }).click();
  await expect(page.getByRole("heading", { name: item!.nameVi })).toBeVisible();
  await expect(page.getByText(item!.address, { exact: true })).toBeVisible();
});
