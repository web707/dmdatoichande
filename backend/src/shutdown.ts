import type { Server } from 'node:http';
import type { EventHub } from './events.js';

export const httpDrainMs = 15_000;

export function createShutdown(
  server: Server,
  hub: EventHub,
  stopListener: () => Promise<void>,
  closePool: () => Promise<void>,
  drainMs = httpDrainMs,
) {
  let stopping: Promise<void> | undefined;
  return () => {
    stopping ??= Promise.resolve().then(async () => {
      const httpClosed = new Promise<void>(resolve => { server.close(() => resolve()); });
      const forceClose = setTimeout(() => server.closeAllConnections(), drainMs);
      const drained = httpClosed.finally(() => clearTimeout(forceClose));
      hub.closeStreams();

      // Keep the pool usable while HTTP handlers finish, including their transactions.
      const closed = await Promise.allSettled([drained.then(closePool), stopListener()]);
      const failure = closed.find(result => result.status === 'rejected');
      if (failure) throw failure.reason;
    });
    return stopping;
  };
}
