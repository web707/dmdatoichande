import 'dotenv/config';
import { test, expect, type Page, type Locator } from '@playwright/test';
import { execFileSync } from 'node:child_process';
import { join } from 'node:path';

const native = process.env.NATIVE_SYNC === '1';
const adbPath = join(process.env.ANDROID_HOME ?? 'D:/android-tools/sdk', 'platform-tools/adb.exe');
function adb(...args: string[]) { return execFileSync(adbPath, ['-s', 'emulator-5554', ...args], { encoding: 'utf8', timeout: 15000 }); }
function nativeXml() {
  const result = adb('shell', 'uiautomator', 'dump', '/sdcard/hanoi-e2e.xml');
  if (!result.includes('dumped')) return '';
  return adb('shell', 'cat', '/sdcard/hanoi-e2e.xml');
}
function tapNative(predicate: (node: string) => boolean) {
  const node = nativeXml().match(/<node[^>]*>/g)?.find(predicate);
  const bounds = node?.match(/bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/);
  if (!bounds) throw new Error('Android control not found');
  adb('shell', 'input', 'tap', String(Math.round((Number(bounds[1])+Number(bounds[3]))/2)), String(Math.round((Number(bounds[2])+Number(bounds[4]))/2)));
}

async function openGuide(page: Page, path = '/places') {
  await page.goto('about:blank');
  await page.goto(`/#${path}`);
  const accessibility = page.locator('flt-semantics-placeholder');
  await accessibility.waitFor({ state: 'attached', timeout: 30000 });
  await accessibility.evaluate((element: HTMLElement) => element.click());
  await expect(page.getByRole('button', { name: 'Refresh guide' })).toBeVisible();
}
async function fill(page: Page, locator: Locator, value: string) {
  await locator.click();
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.insertText(value);
  await expect(locator).toHaveValue(value);
}

test('browse places, map, food, phrase search and persisted bookmarks', async ({ page }) => {
  await openGuide(page);
  await expect(page.getByText('Welcome to Hanoi.', { exact: true })).toBeVisible();
  await fill(page, page.getByRole('textbox', { name: 'Search places, names or addresses' }), 'van mieu');
  await expect(page.getByRole('group', { name: /HISTORY & CULTURE Temple of Literature/ })).toBeVisible();
  await expect(page.getByRole('group', { name: /HISTORY & CULTURE Hoan Kiem Lake/ })).toHaveCount(0);
  await page.getByRole('button', { name: 'View on map' }).click();
  await expect(page.getByText(/Latitude 21.028611/)).toBeVisible();
  await expect(page.getByText(/OpenStreetMap contributors/)).toBeVisible();
  await page.screenshot({ path: '../.local/web-map.png' });
  await page.getByRole('button', { name: 'Food & cafés', exact: true }).click();
  await fill(page, page.getByRole('textbox', { name: /Try/ }), 'pho');
  await expect(page.getByText('Phở Gia Truyền Bát Đàn', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Phrasebook', exact: true }).click();
  await fill(page, page.getByRole('textbox', { name: 'Search in English or Vietnamese' }), 'cam on');
  await expect(page.getByText('Cảm ơn', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Save phrase', exact: true }).click();
  await page.getByRole('button', { name: 'Saved phrases', exact: true }).click();
  await expect(page.getByText('Cảm ơn', { exact: true })).toBeVisible();
  await openGuide(page, '/saved');
  await expect(page.getByText('Cảm ơn', { exact: true })).toBeVisible();
  await page.screenshot({ path: '../.local/web-phrasebook.png' });
});

test('CMS create, update and delete reach another live client without reload', async ({ page, browser, request }) => {
  test.setTimeout(120000);
  const context = await browser.newContext({ viewport: { width: 430, height: 932 } });
  const traveler = await context.newPage();
  await openGuide(traveler, '/phrases');
  const title = `E2Ephrase${Date.now()}`;
  if (native) {
    adb('shell', 'am', 'start', '-W', '-n', 'vn.hanoiguide.hanoi_travel_guide/.MainActivity');
    await expect.poll(() => nativeXml(), { timeout: 15000 }).toContain('content-desc="Phrasebook&#10;Tab');
    tapNative(node => node.includes('content-desc="Phrasebook&#10;Tab'));
    await expect.poll(() => nativeXml(), { timeout: 15000 }).toContain('Say it in Vietnamese.');
    tapNative(node => node.includes('class="android.widget.EditText"'));
    adb('shell', 'input', 'text', title);
    await expect.poll(() => nativeXml(), { timeout: 15000 }).toContain(title);
    adb('shell', 'input', 'keyevent', '66');
    adb('shell', 'input', 'swipe', '540', '1800', '540', '1050', '350');
  }
  await fill(traveler, traveler.getByRole('textbox', { name: 'Search in English or Vietnamese' }), title);
  await openGuide(page, '/admin');
  await page.getByRole('button', { name: 'Sign in', exact: true }).last().click();
  await fill(page, page.getByRole('textbox', { name: 'Email', exact: true }), process.env.ADMIN_EMAIL!);
  await fill(page, page.getByRole('textbox', { name: /Password/ }), process.env.ADMIN_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in', exact: true }).last().click();
  await expect(page.getByText('Keep Hanoi up to date.', { exact: true })).toBeVisible();
  await page.getByRole('checkbox', { name: 'Phrases', exact: true }).click();
  await page.getByRole('button', { name: 'New shared phrase' }).click();
  await fill(page, page.getByRole('textbox', { name: 'Vietnamese phrase', exact: true }), title);
  await fill(page, page.getByRole('textbox', { name: 'English meaning', exact: true }), 'Live synchronization test');
  await fill(page, page.getByRole('textbox', { name: 'Approximate pronunciation', exact: true }), 'test phrase');
  await page.getByRole('button', { name: 'Save changes', exact: true }).click();
  try {
    await expect(traveler.getByText(title, { exact: true })).toBeVisible({ timeout: 8000 });
    if (native) await expect.poll(() => nativeXml(), { timeout: 12000 }).toContain('Live synchronization test');
    await fill(page, page.getByRole('textbox', { name: 'Search this collection', exact: true }), title);
    await page.getByRole('button', { name: 'Edit', exact: true }).click();
    await fill(page, page.getByRole('textbox', { name: 'English meaning', exact: true }), 'Updated from the Web CMS');
    await page.getByRole('button', { name: 'Save changes', exact: true }).click();
    await expect(traveler.getByText('Updated from the Web CMS', { exact: true })).toBeVisible({ timeout: 8000 });
    if (native) {
      await expect.poll(() => nativeXml(), { timeout: 12000 }).toContain('Updated from the Web CMS');
      adb('shell', 'screencap', '-p', '/sdcard/hanoi-sync.png');
      adb('pull', '/sdcard/hanoi-sync.png', '../.local/android-live-sync.png');
    }
    await traveler.screenshot({ path: '../.local/mobile-web-live-sync.png' });
    await page.getByRole('button', { name: 'Delete', exact: true }).click();
    await page.getByRole('button', { name: 'Delete', exact: true }).last().click();
    await expect(traveler.getByText(title, { exact: true })).toHaveCount(0, { timeout: 8000 });
    if (native) await expect.poll(() => nativeXml(), { timeout: 12000 }).toContain('No matching phrases');
  } finally {
    // Remove only this test's unique fixture if an assertion failed mid-flow.
    const login = await request.post('/api/auth/login', { data: { email: process.env.ADMIN_EMAIL, password: process.env.ADMIN_PASSWORD } });
    const { token } = await login.json();
    const rows = await (await request.get('/api/phrases')).json();
    for (const row of rows.filter((row: {vietnamese_text: string}) => row.vietnamese_text === title)) {
      await request.delete(`/api/phrases/${row.id}`, { headers: { Authorization: `Bearer ${token}` } });
    }
    await request.post('/api/auth/logout', { headers: { Authorization: `Bearer ${token}` } });
    await context.close();
  }
});
