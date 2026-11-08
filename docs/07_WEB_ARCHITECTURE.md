# Web architecture

[hanoi-guide-web](../hanoi-guide-web) is an independent Next.js App Router project. Public destination summaries are rendered on the server and search and paging are expressed in the URL. The server accesses only the API URL. The main list uses a short bounded cache. Search and cursor reads avoid unbounded server cache entries.

The detail route reads one destination by UUID on navigation. It displays visit information, coordinates and external map/source links. Cards disable speculative detail fetches. Missing destinations return HTTP 404. API failures display a retry action.

Use the server-rendered flow until a client-side interaction requires cached mutable data. TanStack Query is reserved for interactive features such as Content Studio and realtime invalidation. Lazy-load maps and panoramas at route entry. Validate contrast, keyboard navigation and image sizing before feature cutover.
