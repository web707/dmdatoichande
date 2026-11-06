import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanoi_travel_guide/core/api.dart';
import 'package:hanoi_travel_guide/core/catalog.dart';
import 'package:hanoi_travel_guide/core/store.dart';

class FakeApi extends GuideApi {
  final events = StreamController<Map<String, dynamic>>.broadcast();
  List<CatalogRecord> phrases = [];
  Object? failure;
  @override
  Future<List<CatalogRecord>> fetchRecords(String collection) async {
    if (failure != null) throw failure!;
    return collection == 'phrases' ? phrases : [];
  }

  @override
  Stream<Map<String, dynamic>> watchChanges() => events.stream;
  @override
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password, {
    bool register = false,
  }) async => {'id': 'user1', 'email': email, 'role': 'traveler'};
  @override
  Future<void> logout() async {
    phrases = [];
  }

  @override
  void dispose() {
    events.close();
    super.dispose();
  }
}

void main() {
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  test('bookmarks persist across store instances and toggle off', () async {
    final first = GuideStore(FakeApi(), preferences);
    await first.toggleFavorite('phrase1');
    first.dispose();
    final second = GuideStore(FakeApi(), preferences);
    expect(second.favorites, contains('phrase1'));
    await second.toggleFavorite('phrase1');
    expect(second.favorites, isEmpty);
    second.dispose();
  });
  test('refresh preserves last good data on network failure', () async {
    final api = FakeApi()
      ..phrases = [
        CatalogRecord('phrases', {'id': '1', 'vietnamese_text': 'Hello'}),
      ];
    final store = GuideStore(api, preferences);
    await store.refresh();
    expect(store.list('phrases'), hasLength(1));
    api.failure = const ApiException(0, 'Offline');
    await store.refresh();
    expect(store.list('phrases'), hasLength(1));
    expect(store.error, 'Offline');
    store.dispose();
  });
  test('session expiry clears personal content', () async {
    final api = FakeApi()
      ..phrases = [
        CatalogRecord('phrases', {'id': 'private', 'owner_id': 'user1'}),
      ];
    final store = GuideStore(api, preferences);
    await store.authenticate('a@b.co', 'test-password');
    expect(store.list('phrases'), hasLength(1));
    api.failure = const ApiException(401, 'Please sign in again.');
    await store.refresh();
    expect(store.user, isNull);
    expect(store.list('phrases'), isEmpty);
    store.dispose();
  });
  test('live event refreshes records, logout clears personal data', () async {
    final api = FakeApi();
    final store = GuideStore(api, preferences)..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    api.phrases = [
      CatalogRecord('phrases', {'id': 'new', 'owner_id': 'user1'}),
    ];
    api.events.add({'table': 'phrases'});
    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(store.find('phrases', 'new'), isNotNull);
    expect(store.live, isTrue);
    await store.logout();
    expect(store.list('phrases'), isEmpty);
    store.dispose();
  });
}
