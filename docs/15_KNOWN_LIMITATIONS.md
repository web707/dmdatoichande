# Known limitations

- The independent applications cover the destination read flow. The [parity matrix](migration/FEATURE_PARITY_MATRIX.md) tracks interactive maps, food, phrasebook/TTS, events, emergency, saved items, auth, Content Studio, VR360 and local tools.
- The new clients have different photo presentation behavior. Validate local fallbacks, unavailable remote media and device decoding before claiming visual parity.
- The new native app uses a separate identity. Legacy Android bookmarks and signing continuity require a tested migration.
- Durable replay, native persistent cache, conflict detection, release provisioning and production deployment remain open.
- Local measurements use a small database. Production concurrency, browser vitals, low-end Android frame timing and iOS runtime require separate evidence.
