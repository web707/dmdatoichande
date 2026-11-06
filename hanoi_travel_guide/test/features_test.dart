import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanoi_travel_guide/app/app.dart';
import 'package:hanoi_travel_guide/core/catalog.dart';
import 'package:hanoi_travel_guide/core/store.dart';

import 'store_test.dart' show FakeApi;

class FixtureApi extends FakeApi {
  final Map<String, List<CatalogRecord>> rows = {};
  bool admin = false;
  FixtureApi() {
    final seed =
        jsonDecode(File('backend/seed/catalog.json').readAsStringSync()) as Map;
    for (final type in collections) {
      rows[type] = (seed[type] as List)
          .map(
            (item) =>
                CatalogRecord(type, Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
  }
  @override
  Future<List<CatalogRecord>> fetchRecords(String collection) async =>
      rows[collection]!;
  @override
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password, {
    bool register = false,
  }) async => {
    'id': 'user1',
    'email': email,
    'role': admin ? 'admin' : 'traveler',
  };
  @override
  Future<void> saveRecord(
    String collection,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final key = id ?? 'new-record';
    rows[collection] = [
      ...rows[collection]!.where((r) => r.id != key),
      CatalogRecord(collection, {
        ...data,
        'id': key,
        if (collection == 'phrases' && !admin) 'owner_id': 'user1',
      }),
    ];
  }

  @override
  Future<void> deleteRecord(CatalogRecord record) async {
    rows[record.collection]!.removeWhere((r) => r.id == record.id);
  }
}

Future<GuideStore> mount(
  WidgetTester tester,
  String route, {
  bool admin = false,
  bool signedIn = false,
}) async {
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final api = FixtureApi()..admin = admin;
  final store = GuideStore(api, await SharedPreferences.getInstance());
  if (admin || signedIn) {
    await store.authenticate('demo@hanoi.local', 'test-password');
  } else {
    await store.refresh();
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [guideProvider.overrideWith((ref) => store)],
      child: HanoiApp(initialLocation: route),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String label, String value) async {
  final target = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
  await tester.pump();
}

void main() {
  testWidgets(
    'place detail shows history, culture and coordinates, then handles deletion',
    (tester) async {
      final store = await mount(
        tester,
        '/detail/places/10000000-0000-4000-8000-000000000001',
      );
      expect(find.text('The story'), findsOneWidget);
      expect(find.text('Culture & everyday life'), findsOneWidget);
      expect(find.textContaining('Latitude 21.028889'), findsOneWidget);
      final record = store.list('places').first;
      await store.delete(record);
      await tester.pumpAndSettle();
      expect(find.text('This item is no longer available'), findsOneWidget);
    },
  );
  testWidgets(
    'food search matches accented dishes and lists restaurant addresses',
    (tester) async {
      await mount(tester, '/food');
      expect(find.text('Phở Gia Truyền Bát Đàn'), findsOneWidget);
      expect(find.text('Bún Chả Đắc Kim'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'bat dan');
      await tester.pumpAndSettle();
      expect(find.text('Phở Gia Truyền Bát Đàn'), findsOneWidget);
      expect(find.text('Bún Chả Đắc Kim'), findsNothing);
      await tester.enterText(find.byType(TextField), 'not-found');
      await tester.pumpAndSettle();
      expect(find.text('No dishes found'), findsOneWidget);
    },
  );
  testWidgets('traveller creates, edits and deletes a personal phrase', (
    tester,
  ) async {
    final store = await mount(tester, '/phrases', signedIn: true);
    await tap(tester, find.text('Add my phrase'));
    await tap(tester, find.text('Save changes'));
    expect(find.text('This field is required'), findsWidgets);
    await fill(tester, 'Vietnamese phrase', 'Câu riêng');
    await fill(tester, 'English meaning', 'My personal phrase');
    await fill(tester, 'Approximate pronunciation', 'gow ree-eng');
    await fill(tester, 'Usage note (English)', 'A personal note');
    await tap(tester, find.text('Save changes'));
    expect(store.list('phrases').last.isPrivate, isTrue);
    await tap(tester, find.text('Edit').last);
    await fill(tester, 'English meaning', 'Updated personal phrase');
    await tap(tester, find.text('Save changes'));
    expect(store.list('phrases').last.subtitle, 'Updated personal phrase');
    await tap(tester, find.text('Delete').last);
    await tap(tester, find.text('Keep it'));
    expect(store.find('phrases', 'new-record'), isNotNull);
    await tap(tester, find.text('Delete').last);
    await tap(tester, find.text('Delete').last);
    expect(store.find('phrases', 'new-record'), isNull);
  });
  testWidgets('CMS validates coordinates and saves edits to a place', (
    tester,
  ) async {
    final store = await mount(tester, '/admin', admin: true);
    await tap(tester, find.text('Edit').first);
    await fill(tester, 'Latitude', '105.85');
    await tap(tester, find.text('Save changes'));
    expect(find.text('Enter a number between -90 and 90'), findsOneWidget);
    await fill(tester, 'Latitude', '21.04');
    await fill(tester, 'English name', 'Edited lake');
    await tap(tester, find.text('Preview image'));
    await tap(tester, find.text('Save changes'));
    expect(
      store.find('places', '10000000-0000-4000-8000-000000000001')!.latitude,
      21.04,
    );
    expect(find.text('Edited lake'), findsOneWidget);
    await tap(tester, find.text('Phrases').first);
    await tap(tester, find.text('New shared phrase'));
    await tap(tester, find.text('Cancel'));
    await tap(tester, find.text('Food & restaurants'));
    await tap(tester, find.text('Edit').first);
    await fill(tester, 'Dish key (e.g. pho-bo)', 'INVALID KEY');
    await tap(tester, find.text('Save changes'));
    expect(
      find.text('Use lowercase words separated by hyphens'),
      findsOneWidget,
    );
    await tap(tester, find.text('Cancel'));
  });
  testWidgets(
    'sign-in form validates input and supports register and sign-out',
    (tester) async {
      final store = await mount(tester, '/phrases');
      await tap(tester, find.text('Sign in').first);
      await tap(tester, find.text('Sign in').last);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      await tap(tester, find.text('New here? Create an account'));
      await fill(tester, 'Email', 'person@example.org');
      await fill(tester, 'Password', 'long-password');
      await tap(tester, find.text('Create account'));
      expect(store.user?['email'], 'person@example.org');
      await tap(tester, find.text('Account'));
      await tap(tester, find.text('Sign out'));
      expect(store.user, isNull);
    },
  );
  testWidgets('map shows current marker coordinates and missing record state', (
    tester,
  ) async {
    final store = await mount(
      tester,
      '/map/foods_restaurants/20000000-0000-4000-8000-000000000001',
    );
    expect(find.text('Phở Gia Truyền Bát Đàn'), findsOneWidget);
    expect(find.textContaining('Latitude 21.033638'), findsOneWidget);
    await store.delete(store.list('foods_restaurants').first);
    await tester.pumpAndSettle();
    expect(find.text('This item is no longer available'), findsOneWidget);
  });
}
