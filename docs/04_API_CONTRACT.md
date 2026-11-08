# Versioned API contract

The initial public operation is [GET /api/v1/destinations](../hanoi-guide-contracts/openapi/destinations-v1.json). The default page contains up to 20 records with a server-enforced maximum of 50. Repeat the same search and pass `nextCursor` unchanged for the next page. A null cursor indicates the last page. Item IDs come from `places.id`.

The list matches a literal substring of either name or address after case, accent and whitespace normalization. Search uses PostgreSQL 18 Unicode collation with UTF-8 data. The detail read at `GET /api/v1/destinations/{id}` preserves the list fields and adds history, culture, location and visit information. The USD price is a decimal string to preserve database precision. Both successful public operations can be revalidated with ETags.

The contract owns generated TypeScript and Kotlin models. A client can build against its checked-in copy and verify drift when the contract project is available. See the [existing HTTP inventory](api/API_INVENTORY.md) for the separate legacy API surface.
