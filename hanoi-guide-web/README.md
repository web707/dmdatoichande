# Hanoi Guide Web

Independent Next.js application for the public destination catalog. The list and detail routes read `GET /api/v1/destinations` and `GET /api/v1/destinations/:id` from the shared Express API. The list includes search, pagination, loading, empty, and retry states. Details include history, culture, visit information and a link to OpenStreetMap.

## Local development

Requires Node.js 24 and npm. From this directory:

```powershell
npm ci
Copy-Item .env.example .env.local
npm run dev
```

Open `http://127.0.0.1:8081/destinations`. The package's development and local production commands bind to loopback. Set `HANOI_GUIDE_API_URL` in `.env.local` to the backend origin when it differs from `http://127.0.0.1:8090`. For production, set it in the Next.js server environment. Builds do not require a running API.

## Verification

```powershell
npm run lint
npm run typecheck
npm run build
npx playwright install chromium
npm run test:e2e
```

The Playwright suite starts the production Web build on port 8181 and a labeled HTTP fixture on port 8182. To check identity and order against a running database-backed API, set `HANOI_GUIDE_REAL_API_URL` before `npm run test:e2e`. This mode only reads from the configured backend.

`npm run contract:check` is a workspace-level check for the bundled TypeScript models and requires the sibling `hanoi-guide-contracts` directory. The standalone build uses the checked-in copy.

## Data loading

- Server rendering sends the initial content to the browser and avoids a client request directly to the API.
- The unfiltered first page revalidates every 20 seconds when requested. Search, pagination, and detail requests are fetched on demand with a five-second timeout. The browser does not prefetch detail records from the catalog.
- The bundled photographs use responsive WebP variants. Other catalog photographs load directly in the browser to keep external image processing off the Web server.
