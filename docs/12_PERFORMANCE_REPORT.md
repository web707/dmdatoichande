# Performance measurements

The initial benchmark compares destination transport against PostgreSQL 18.1 with five existing destination records. The old full list is measured from baseline `fe2627e` on port 8092. The new list uses the same database on port 8090. [measure-catalog.mjs](../scripts/measure-catalog.mjs) warms both paths, checks the ordered data projection, and times 40 requests per scenario from Node.js 24 on the same Windows host.

The original list body was 8,417 bytes and the versioned list body was 2,547 bytes, a 69.7% reduction for five summaries. A Flutter catalog reconciliation transfers 22,962 response-body bytes over four requests on the same data. It refreshes additional collections, so it represents workload context for Phase 1.

| Local loopback path | p50 | p95 | p99 |
| --- | ---: | ---: | ---: |
| Legacy destination list | 5.53 ms | 13.89 ms | 18.20 ms |
| Legacy four-request reconciliation | 6.34 ms | 14.60 ms | 17.75 ms |
| Versioned destination list | 6.78 ms | 16.07 ms | 18.48 ms |

The run against the combined API returned HTTP 304 with a zero-byte body. The new list reduced JSON bytes. Its observed loopback latency was slightly higher than the legacy list.

## Browser and Android observations

Phase 1 Chromium 156 measurements used three fresh 1440×900 browser contexts per site, disabled browser cache and service workers, and sampled until the catalog appeared plus 1.5 seconds. Flutter used the existing build at `http://localhost:8090/#/places`. Next.js used its production list build at `http://127.0.0.1:8181/destinations` before detail navigation was added.

| Catalog navigation | Flutter | Next.js list |
| --- | ---: | ---: |
| Observed total transfer | 6,849,108 B | 330,809 B |
| Tracked requests | 25 | 14 |
| Browser API responses | 10 | 0 |
| Script and WASM transfer | 4,761,982 B | 141,383 B |

The comparison includes differences in feature scope, static compression and API strategy. Both attempted three unavailable external image URLs. Web used visual placeholders for those records. The new detail path fetches detail data on navigation so its cost is separate from the initial list.

The initial native build produced a 12,256,833-byte debug APK and a 1,323,057-byte unsigned release APK with R8 and resource shrinking. The Android API 34 x86_64 emulator displayed all five live records and matched search results. One debug process snapshot reported 71,509 KiB PSS. The second cold activity launch reported 4,396 ms using `adb shell am start -W`; this measures activity launch on a loaded development host. Time to first visible catalog, comparable Flutter timing, scrolling smoothness and production release runtime still require measurement.

The final catalog and detail build produced a 12,273,241-byte debug APK and a 1,339,469-byte unsigned release APK. The final debug APK passed emulator search, detail and system Back checks against the combined backend.

Local loopback measurements cannot establish production latency, browser responsiveness or Android frame pacing. For equivalent full-feature releases, collect browser LCP, INP, CLS, bytes and requests, plus Android startup, frame timing, peak PSS, battery and network. Profile the database under representative catalog sizes and concurrently connected clients before choosing production indexes or resource budgets.
