import 'dotenv/config';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import pg from 'pg';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { createApp } from '../src/app.js';
import { EventHub } from '../src/events.js';
import { hashPassword } from '../src/security.js';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const hub = new EventHub();
const app = createApp(pool, hub, ['http://localhost:8080']);
const tag = randomUUID().slice(0, 8);
const emails = [`admin-${tag}@test.local`, `alice-${tag}@test.local`, `bob-${tag}@test.local`];
let admin = ''; let alice = ''; let bob = '';
let phraseId = ''; let placeId = ''; let foodId = '';
const phrase = { vietnamese_text: `Xin chào ${tag}`, english_meaning: 'Hello', pronunciation_guide: 'sin chow (approximate)', category: 'greetings' };
const place = { name_vi: `Test ${tag}`, name_en: `Test ${tag}`, summary_en: 'Summary', history_en: 'History', culture_en: 'Culture', image_url: 'https://example.org/lake.jpg', image_credit: 'Test fixture', address: 'Hanoi', latitude: 21.03, longitude: 105.85 };
describe('real PostgreSQL API permissions and CRUD', () => {
  beforeAll(async () => {
    await pool.query('INSERT INTO users(email,password_hash,role) VALUES($1,$2,$3)', [emails[0], await hashPassword('Test-password-123!'), 'admin']);
    const a = await request(app).post('/api/auth/login').send({ email: emails[0], password: 'Test-password-123!' });
    admin = a.body.token;
    for (const [i, email] of emails.slice(1).entries()) {
      const result = await request(app).post('/api/auth/register').send({ email, password: 'Test-password-123!' });
      expect(result.status).toBe(201);
      if (i === 0) alice = result.body.token; else bob = result.body.token;
    }
  });
  afterAll(async () => {
    await pool.query('DELETE FROM phrases WHERE vietnamese_text LIKE $1', [`%${tag}%`]);
    await pool.query('DELETE FROM places WHERE name_vi=$1', [place.name_vi]);
    await pool.query('DELETE FROM foods_restaurants WHERE food_key=$1', [`test-${tag}`]);
    await pool.query('DELETE FROM users WHERE email = ANY($1::text[])', [emails]);
    await pool.end();
  });
  it('exposes health and rejects unknown collections and disallowed origins', async () => {
    expect((await request(app).get('/api/health')).status).toBe(200);
    expect((await request(app).get('/api/users')).status).toBe(404);
    expect((await request(app).get('/api/places').set('Origin', 'https://evil.example')).status).toBe(403);
    expect((await request(app).get('/api/places').set('Origin', 'http://localhost:8080')).headers['access-control-allow-origin']).toBe('http://localhost:8080');
  });
  it('rejects weak passwords, bad login, duplicate email and forged roles', async () => {
    expect((await request(app).post('/api/auth/register').send({ email: 'a@b.co', password: 'short' })).status).toBe(400);
    expect((await request(app).post('/api/auth/register').send({ email: emails[1], password: 'Test-password-123!' })).status).toBe(409);
    expect((await request(app).post('/api/auth/login').send({ email: emails[1], password: 'wrong-password' })).status).toBe(401);
    expect((await request(app).post('/api/auth/register').send({ email: 'forged@test.local', password: 'Test-password-123!', role: 'admin' })).status).toBe(400);
    expect((await request(app).get('/api/auth/me').set('Authorization', 'Bearer forged')).status).toBe(401);
    expect((await request(app).get('/api/auth/me').auth(alice, { type: 'bearer' })).body.user.role).toBe('traveler');
  });
  it('permits only admins to create and edit places', async () => {
    expect((await request(app).post('/api/places').send(place)).status).toBe(401);
    expect((await request(app).post('/api/places').auth(alice, { type: 'bearer' }).send(place)).status).toBe(403);
    expect((await request(app).post('/api/places').auth(admin, { type: 'bearer' }).send({ ...place, latitude: 105 })).status).toBe(400);
    const created = await request(app).post('/api/places').auth(admin, { type: 'bearer' }).send(place);
    expect(created.status).toBe(201); placeId = created.body.id;
    const edited = await request(app).put(`/api/places/${placeId}`).auth(admin, { type: 'bearer' }).send({ ...place, latitude: 21.04 });
    expect(edited.status).toBe(200); expect(edited.body.latitude).toBe(21.04);
    expect((await request(app).get('/api/places')).body.some((p: {id: string}) => p.id === placeId)).toBe(true);
  });
  it('isolates private phrases and prevents ownership spoofing', async () => {
    const created = await request(app).post('/api/phrases').auth(alice, { type: 'bearer' }).send(phrase);
    expect(created.status).toBe(201); phraseId = created.body.id;
    expect(created.body.owner_id).toBeTruthy();
    for (const token of ['', bob, admin]) {
      const query = request(app).get('/api/phrases');
      if (token) query.auth(token, { type: 'bearer' });
      expect((await query).body.some((p: {id: string}) => p.id === phraseId)).toBe(false);
    }
    expect((await request(app).get('/api/phrases').auth(alice, { type: 'bearer' })).body.some((p: {id: string}) => p.id === phraseId)).toBe(true);
    expect((await request(app).put(`/api/phrases/${phraseId}`).auth(bob, { type: 'bearer' }).send(phrase)).status).toBe(404);
    expect((await request(app).post('/api/phrases').auth(alice, { type: 'bearer' }).send({ ...phrase, owner_id: null })).status).toBe(400);
    expect((await request(app).put(`/api/phrases/${phraseId}`).auth(alice, { type: 'bearer' }).send({ ...phrase, english_meaning: 'Hi' })).body.english_meaning).toBe('Hi');
  });
  it('publishes admin phrases and groups food addresses', async () => {
    const common = await request(app).post('/api/phrases').auth(admin, { type: 'bearer' }).send(phrase);
    expect(common.body.owner_id).toBeNull();
    const food = { food_key: `test-${tag}`, food_name_vi: 'Phở', food_name_en: 'Pho', description_en: 'Noodle soup', restaurant_name: 'Test restaurant', address: 'Hanoi', latitude: 21.03, longitude: 105.85 };
    const created = await request(app).post('/api/foods_restaurants').auth(admin, { type: 'bearer' }).send(food);
    expect(created.status).toBe(201); foodId = created.body.id;
    expect((await request(app).put(`/api/foods_restaurants/${foodId}`).auth(admin, { type: 'bearer' }).send({ ...food, food_name_en: 'Beef pho' })).body.food_name_en).toBe('Beef pho');
    expect((await request(app).delete(`/api/phrases/${common.body.id}`).auth(alice, { type: 'bearer' })).status).toBe(404);
    expect((await request(app).delete(`/api/phrases/${common.body.id}`).auth(admin, { type: 'bearer' })).status).toBe(204);
  });
  it('deletes only authorized records and revokes sessions on logout', async () => {
    expect((await request(app).delete(`/api/places/${placeId}`).auth(bob, { type: 'bearer' })).status).toBe(403);
    expect((await request(app).delete(`/api/places/${placeId}`).auth(admin, { type: 'bearer' })).status).toBe(204);
    expect((await request(app).delete(`/api/places/${placeId}`).auth(admin, { type: 'bearer' })).status).toBe(404);
    expect((await request(app).delete('/api/places/not-a-uuid').auth(admin, { type: 'bearer' })).status).toBe(400);
    expect((await request(app).delete(`/api/phrases/${phraseId}`).auth(alice, { type: 'bearer' })).status).toBe(204);
    expect((await request(app).post('/api/auth/logout').auth(alice, { type: 'bearer' })).status).toBe(204);
    expect((await request(app).get('/api/auth/me').auth(alice, { type: 'bearer' })).status).toBe(401);
  });
});
