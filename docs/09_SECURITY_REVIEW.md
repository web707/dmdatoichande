# Security review

The baseline API uses strict Zod inputs, parameterized SQL, allowlisted dynamic identifiers, an origin allowlist, a 64 KiB JSON body limit and API/auth rate limiting. Credentials use scrypt with random salt and constant-time verification. PostgreSQL stores session digests and enforces expiry at authentication. Owner filtering for phrases applies even to admins.

The destination operations expose explicit public fields. The same Express origin policy and rate limit apply. The clients render descriptions as plain text. API tests exercise malformed search, pagination and detail IDs. The 2026-11-08 npm audit reported zero production advisories in both Node lockfiles.

The API generates a server-owned request ID and exposes it through the allowed CORS response headers. Default logs include completed 5xx responses. Diagnostic mode adds other requests, using route templates, bounded method/status metadata and SQLSTATE. Tests verify that tokens, query strings, custom IDs and driver error messages do not appear in logs.

Before production, exercise per-process rate limiting behind the chosen proxy, protect Web session cookies with CSRF controls, and test secure platform credential storage. The Pannellum route has its own embedding CSP. Review each frontend's security headers separately.
