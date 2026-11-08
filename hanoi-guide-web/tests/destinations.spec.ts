import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.route("https://images.example.test/**", (route) => route.abort());
});

test("renders destinations from the shared API in the initial HTML", async ({ page }) => {
  const response = await page.goto("/destinations");
  expect(response?.ok()).toBe(true);
  expect(await response?.text()).toContain("Hoan Kiem Lake");
  await expect(page.getByRole("heading", { name: "Hồ Hoàn Kiếm" })).toBeVisible();
  await expect(page.getByText("Hoàn Kiếm, Hà Nội", { exact: true })).toBeVisible();
});

test("reuses the default catalog fetch across visits within its freshness window", async ({ page, request }) => {
  const requestCount = async () => Number(await (await request.get("http://127.0.0.1:8182/default-page-requests")).text());
  await page.goto("/destinations");
  await expect(page.getByRole("heading", { name: "Hồ Hoàn Kiếm" })).toBeVisible();
  const count = await requestCount();
  await page.reload();
  await expect(page.getByRole("heading", { name: "Hồ Hoàn Kiếm" })).toBeVisible();
  expect(await requestCount()).toBe(count);
});

test("searches and pages using the URL on a narrow viewport", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/destinations");
  await page.getByRole("searchbox", { name: "Tìm điểm đến" }).fill("Hà Nội");
  await page.getByRole("button", { name: "Tìm kiếm" }).click();
  await expect(page.getByRole("heading", { name: "Hồ Hoàn Kiếm" })).toBeVisible();
  await page.getByRole("link", { name: "Trang sau" }).click();
  await expect(page.getByRole("heading", { name: "Văn Miếu" })).toBeVisible();
  const params = new URL(page.url()).searchParams;
  expect(params.get("q")).toBe("Hà Nội");
  expect(params.get("cursor")).toBe("page-two");
  expect(await page.locator("html").evaluate((element) => element.scrollWidth)).toBe(390);
});

test("shows a useful empty state", async ({ page }) => {
  await page.goto(`/destinations?q=${encodeURIComponent("không có kết quả")}`);
  await expect(page.getByRole("heading", { name: "Không tìm thấy điểm đến" })).toBeVisible();
});

test("shows a loading state before a delayed response", async ({ page }) => {
  await page.goto("/destinations?q=slow", { waitUntil: "commit" });
  await expect(page.getByText("Đang tải điểm đến…", { exact: true })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Hồ Hoàn Kiếm" })).toBeVisible();
});

test("can retry an API failure", async ({ page }) => {
  await page.goto("/destinations?q=retry");
  await expect(page.getByRole("heading", { name: "Chưa thể tải điểm đến" })).toBeVisible();
  await page.getByRole("link", { name: "Thử lại" }).click();
  await expect(page.getByRole("heading", { name: "Hồ Hoàn Kiếm" })).toBeVisible();
});

test("handles a response that breaks the destination contract", async ({ page }) => {
  await page.goto("/destinations?q=invalid-shape");
  await expect(page.getByRole("heading", { name: "Chưa thể tải điểm đến" })).toBeVisible();
});

test("shows a recoverable state when the API times out", async ({ page }) => {
  await page.goto("/destinations?q=timeout");
  await expect(page.getByRole("link", { name: "Thử lại" })).toBeVisible({ timeout: 8_000 });
});

test("links to details on demand with pending feedback and a single detail fetch", async ({ page, request }) => {
  const requestCount = async () => Number(await (await request.get("http://127.0.0.1:8182/detail-requests")).text());
  const before = await requestCount();
  await page.goto("/destinations");
  const detailLink = page.getByRole("link", { name: "Hồ Hoàn Kiếm" });
  await expect(detailLink).toBeVisible();
  expect(await requestCount()).toBe(before);
  await detailLink.click();
  await expect(page.getByText("Đang mở điểm đến…", { exact: true })).toBeVisible();
  await expect(page.getByRole("heading", { level: 1, name: "Hồ Hoàn Kiếm" })).toBeVisible();
  await expect(page).toHaveTitle("Hồ Hoàn Kiếm · Hanoi Guide");
  await expect(page.getByText("A historic lake with a story of a returned sword.")).toBeVisible();
  await expect(page.getByRole("link", { name: "Nguồn thông tin" })).toHaveAttribute("href", "https://example.test/destination-source");
  await expect(page.getByRole("link", { name: "Xem trên OpenStreetMap" })).toHaveAttribute("href", /mlat=21\.0287&mlon=105\.8522/);
  expect(await requestCount()).toBe(before + 1);
});

test("returns HTTP 404 for missing or malformed detail IDs", async ({ page }) => {
  for (const id of ["00000000-0000-4000-8000-000000000000", "invalid"]) {
    const response = await page.goto(`/destinations/${id}`);
    expect(response?.status()).toBe(404);
    await expect(page.getByRole("heading", { level: 1, name: "Không tìm thấy điểm đến" })).toBeVisible();
  }
});

test("can retry detail errors and omits unsafe source URLs", async ({ page }) => {
  await page.goto("/destinations/fb8bb849-97ee-45ea-a93c-40f0535c25b6");
  await expect(page.getByRole("heading", { name: "Chưa thể tải thông tin điểm đến" })).toBeVisible();
  await page.getByRole("link", { name: "Thử lại" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Văn Miếu" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Nguồn thông tin" })).toHaveCount(0);
});
