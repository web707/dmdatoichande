import { EventEmitter } from 'node:events';
import pg from 'pg';
import { collections } from './validation.js';

export class EventHub extends EventEmitter {
  #shuttingDown = false;
  constructor() { super(); this.setMaxListeners(200); }
  get isShuttingDown() { return this.#shuttingDown; }
  publish(table: string) { if (collections.includes(table as typeof collections[number])) this.emit('change', table); }
  closeStreams() {
    if (this.#shuttingDown) return;
    this.#shuttingDown = true;
    this.emit('shutdown');
  }
}

// LISTEN uses its own connection; trigger notifications arrive only after COMMIT.
export function listenForChanges(connectionString: string, hub: EventHub): () => Promise<void> {
  let stopped = false;
  let client: pg.Client | undefined;
  let timer: NodeJS.Timeout | undefined;
  const connect = async () => {
    const current = new pg.Client({ connectionString, connectionTimeoutMillis: 5000 });
    client = current;
    let reconnecting = false;
    const retry = () => {
      if (stopped || reconnecting) return;
      reconnecting = true;
      hub.emit('offline');
      void current.end().catch(() => {});
      timer = setTimeout(() => void connect(), 2000);
    };
    current.on('error', retry);
    current.on('end', retry);
    current.on('notification', message => {
      if (message.channel === 'catalog_changed' && message.payload) hub.publish(message.payload);
    });
    try {
      await current.connect();
      await current.query('LISTEN catalog_changed');
      if (!stopped) hub.emit('ready');
    } catch { retry(); }
  };
  void connect();
  return async () => { stopped = true; clearTimeout(timer); await client?.end().catch(() => {}); };
}
