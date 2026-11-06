import 'package:flutter_test/flutter_test.dart';
import 'package:hanoi_travel_guide/core/catalog.dart';

void main() {
  test('Vietnamese search ignores accents, case and whitespace', () {
    expect(normalizeSearch('  PHỞ Bát Đàn  '), 'pho bat dan');
    expect(normalizeSearch('Đường đi'), 'duong di');
    expect(normalizeSearch(''), '');
  });
  test('coordinates reject reversed latitude and nonfinite numbers', () {
    expect(validCoordinates(21.0287, 105.8524), isTrue);
    expect(validCoordinates(105.8524, 21.0287), isFalse);
    expect(validCoordinates(double.nan, 105), isFalse);
    expect(validCoordinates(21, double.infinity), isFalse);
  });
  test('food grouping preserves all restaurant locations', () {
    final rows = [
      CatalogRecord('foods_restaurants', {
        'id': '1',
        'food_key': 'pho',
        'food_name_vi': 'Phở',
        'restaurant_name': 'A',
      }),
      CatalogRecord('foods_restaurants', {
        'id': '2',
        'food_key': 'pho',
        'food_name_vi': 'Phở',
        'restaurant_name': 'B',
      }),
    ];
    expect(groupFoods(rows)['pho']!.length, 2);
    expect(rows.first.matches('phO'), isTrue);
    expect(rows.first.matches('bun cha'), isFalse);
  });
}
