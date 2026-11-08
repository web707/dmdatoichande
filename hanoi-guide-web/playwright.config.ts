import { defineConfig, devices } from "@playwright/test";

const realApi = process.env.HANOI_GUIDE_REAL_API_URL;
const fixtureApi = "http://127.0.0.1:8182";
const webUrl = "http://127.0.0.1:8181";

export default defineConfig({
  testDir: "./tests",
  testMatch: realApi ? "live.spec.ts" : "destinations.spec.ts",
  workers: 1,
  use: {
    ...devices["Desktop Chrome"],
    baseURL: webUrl,
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  webServer: [
    ...(realApi ? [] : [{ command: "node tests/fixtures/api.mjs", url: `${fixtureApi}/health` }]),
    {
      command: "node node_modules/next/dist/bin/next start --hostname 127.0.0.1 --port 8181",
      url: webUrl,
      env: { HANOI_GUIDE_API_URL: realApi ?? fixtureApi },
    },
  ],
});
