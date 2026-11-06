import { describe, expect, it } from 'vitest';
import { parseRecord } from '../src/validation.js';
import { hashPassword, verifyPassword } from '../src/security.js';

const place = { name_vi: 'Hồ Hoàn Kiếm', name_en: 'Hoan Kiem Lake', summary_en: 'Lake', history_en: 'History', culture_en: 'Culture', image_url: 'https://example.org/lake.jpg', image_credit: 'Author / CC BY-SA', address: 'Hanoi', latitude: 21.0287, longitude: 105.8524 };
describe('catalog validation', () => {
  it('accepts a complete place and trims text', () => {
    expect(parseRecord('places', { ...place, name_en: ' Lake ' }).name_en).toBe('Lake');
  });
  it.each([91, -91, NaN, Infinity])('rejects invalid latitude %s', latitude => {
    expect(() => parseRecord('places', { ...place, latitude })).toThrow();
  });
  it('rejects swapped coordinates, empty history, unsafe images and extra owner fields', () => {
    for (const update of [{ latitude: 105, longitude: 21 }, { history_en: ' ' }, { image_url: 'javascript:alert(1)' }, { owner_id: 'spoofed' }]) {
      expect(() => parseRecord('places', { ...place, ...update })).toThrow();
    }
  });
  it('validates pronunciation and categories', () => {
    expect(() => parseRecord('phrases', { vietnamese_text: 'Xin chào', english_meaning: 'Hello', pronunciation_guide: '', category: 'greetings' })).toThrow();
    expect(parseRecord('phrases', { vietnamese_text: 'Xin chào', english_meaning: 'Hello', pronunciation_guide: 'sin chow (approximate)', category: 'greetings' }).category).toBe('greetings');
  });
  it('rejects arbitrary table names', () => expect(() => parseRecord('users', {})).toThrow());
});
describe('password hashing', () => {
  it('salts passwords and verifies without accepting a wrong password', async () => {
    const first = await hashPassword('correct-password');
    const second = await hashPassword('correct-password');
    expect(first).not.toBe(second);
    expect(await verifyPassword('correct-password', first)).toBe(true);
    expect(await verifyPassword('wrong-password', first)).toBe(false);
    expect(await verifyPassword('correct-password', 'invalid')).toBe(false);
  });
});
