# Hanoi Guide API contracts

The OpenAPI document is the source for the public destination API's TypeScript and Kotlin models. The legacy `GET /api/places` contract is independent.

From the workspace root, regenerate the models with `node hanoi-guide-contracts/generate.mjs` and verify them with `node hanoi-guide-contracts/generate.mjs --check`. The generator requires no package install.

Fetch the first page from `GET /api/v1/destinations`. To fetch another page, send the returned `nextCursor` as `cursor` with the same search term. Start from the first page after changing the search term. A null cursor means the list has ended. Pages are live catalog reads, so refresh from the first page to see newly committed changes.
