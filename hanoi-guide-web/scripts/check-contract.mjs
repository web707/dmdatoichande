import { readFile } from "node:fs/promises";

const [source, local] = await Promise.all([
  readFile(new URL("../../hanoi-guide-contracts/generated-typescript/destinations.ts", import.meta.url)),
  readFile(new URL("../src/services/generated/destinations.ts", import.meta.url)),
]);

if (!source.equals(local)) {
  console.error("Destination model differs from the shared contract. Refresh the local copy.");
  process.exitCode = 1;
}
