const collections = ['places', 'phrases', 'foods_restaurants', 'events'];

String normalizeSearch(String value) {
  var result = value.toLowerCase().trim();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    for (final char in entry.value.split('')) {
      result = result.replaceAll(char, entry.key);
    }
  }
  return result
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool validCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude.abs() <= 90 &&
    longitude.abs() <= 180;

class CatalogRecord {
  final String collection;
  final Map<String, dynamic> data;
  CatalogRecord(this.collection, Map<String, dynamic> data)
    : data = Map.unmodifiable(data);
  String text(String field) => data[field]?.toString() ?? '';
  String get id => text('id');
  String get title => text(switch (collection) {
    'places' => 'name_en',
    'phrases' => 'vietnamese_text',
    'foods_restaurants' => 'food_name_vi',
    'events' => 'name_en',
    _ => 'name_en',
  });
  String get subtitle => text(switch (collection) {
    'places' => 'name_vi',
    'phrases' => 'english_meaning',
    'foods_restaurants' => 'food_name_en',
    'events' => 'name_vi',
    _ => '',
  });
  double get latitude => (data['latitude'] as num?)?.toDouble() ?? 0;
  double get longitude => (data['longitude'] as num?)?.toDouble() ?? 0;
  bool get hasLocation =>
      data['latitude'] != null &&
      data['longitude'] != null &&
      (data['latitude'] as num).toDouble().abs() <= 90 &&
      (data['longitude'] as num).toDouble().abs() <= 180;
  bool get isPrivate => data['owner_id'] != null;
  bool matches(String query) {
    const fields = [
      'name_en',
      'name_vi',
      'vietnamese_text',
      'english_meaning',
      'category',
      'food_name_vi',
      'food_name_en',
      'restaurant_name',
      'address',
      'description_en',
      'location_name',
    ];
    final normalized = normalizeSearch(query);
    return normalized.isEmpty ||
        fields.any(
          (field) => normalizeSearch(text(field)).contains(normalized),
        );
  }
}

Map<String, List<CatalogRecord>> groupFoods(List<CatalogRecord> rows) {
  final groups = <String, List<CatalogRecord>>{};
  for (final row in rows) {
    groups.putIfAbsent(row.text('food_key'), () => []).add(row);
  }
  return groups;
}
