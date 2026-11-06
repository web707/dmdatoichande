import { z } from 'zod';

export const collections = ['places', 'phrases', 'foods_restaurants', 'events'] as const;
export type Collection = typeof collections[number];
export const collectionSchema = z.enum(collections);
const text = z.string().trim().min(1).max(6000);
const short = z.string().trim().min(1).max(250);
const optional = z.string().trim().max(6000).default('');
const httpsUrl = z.url().refine(value => value.startsWith('https://'), 'Use an HTTPS image URL');
const coordinates = { latitude: z.number().min(-90).max(90), longitude: z.number().min(-180).max(180) };
const placeSchema = z.object({
  name_vi: short, name_en: short, summary_en: text, history_en: text, culture_en: text,
  image_url: httpsUrl, image_credit: short, address: text, ...coordinates,
  source_url: z.union([z.url(), z.literal('')]).default(''),
  opening_hours: optional,
  ticket_price_vnd: z.number().int().min(0).max(10000000).default(0),
  ticket_price_usd: z.number().min(0).max(9999).default(0),
  booking_info: optional,
  visit_duration_min: z.number().int().min(0).max(1440).default(0),
  best_time_to_visit: optional,
}).strict();
const phraseSchema = z.object({
  vietnamese_text: short, english_meaning: text, pronunciation_guide: text,
  ipa: optional, category: z.enum(['greetings', 'shopping', 'food', 'directions', 'other']), usage_note_en: optional,
}).strict();
const foodSchema = z.object({
  food_key: z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/).max(100),
  food_name_vi: short, food_name_en: short, description_en: text,
  restaurant_name: short, address: text, ...coordinates,
  image_url: z.union([httpsUrl, z.literal('')]).default(''), image_credit: optional,
  source_url: z.union([z.url(), z.literal('')]).default(''),
}).strict().refine(value => !value.image_url || value.image_credit.length > 0, { message: 'Image credit is required', path: ['image_credit'] });
const eventSchema = z.object({
  name_vi: short, name_en: short, description_en: text,
  event_date_start: z.string().trim().max(20).default(''),
  event_date_end: z.string().trim().max(20).default(''),
  is_recurring: z.boolean().default(false),
  recurrence_note: optional,
  location_name: optional,
  latitude: z.number().min(-90).max(90).nullish(),
  longitude: z.number().min(-180).max(180).nullish(),
  image_url: z.union([httpsUrl, z.literal('')]).default(''),
  image_credit: optional,
  source_url: z.union([z.url(), z.literal('')]).default(''),
}).strict();
export function parseRecord(collection: string, input: unknown): Record<string, unknown> {
  const type = collectionSchema.parse(collection);
  return ({ places: placeSchema, phrases: phraseSchema, foods_restaurants: foodSchema, events: eventSchema }[type]).parse(input);
}
export const credentialsSchema = z.object({ email: z.email().trim().toLowerCase().max(254), password: z.string().min(10).max(128) }).strict();
export const uuidSchema = z.uuid();
