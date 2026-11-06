import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanoi_travel_guide/app/app.dart';
import 'package:hanoi_travel_guide/core/store.dart';
import 'package:hanoi_travel_guide/core/catalog.dart';

import 'store_test.dart' show FakeApi;

void main() {
  testWidgets('traveler can browse phrasebook, search and bookmark', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi()
      ..phrases = [
        CatalogRecord('phrases', {
          'id': 'hello',
          'vietnamese_text': 'Xin chào',
          'english_meaning': 'Hello',
          'pronunciation_guide': 'sin chow',
          'category': 'greetings',
        }),
      ];
    final store = GuideStore(api, await SharedPreferences.getInstance());
    await store.refresh();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [guideProvider.overrideWith((ref) => store)],
        child: const HanoiApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phrasebook').first);
    await tester.pumpAndSettle();
    expect(find.text('Xin chào'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Save phrase'));
    await tester.tap(find.byTooltip('Save phrase'));
    await tester.pumpAndSettle();
    expect(store.favorites, contains('hello'));
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'not a phrase');
    await tester.pumpAndSettle();
    expect(find.text('No matching phrases'), findsOneWidget);
  });
  testWidgets('admin page requires authentication', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = GuideStore(FakeApi(), await SharedPreferences.getInstance());
    await store.refresh();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [guideProvider.overrideWith((ref) => store)],
        child: const HanoiApp(initialLocation: '/admin'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Administrator access'), findsOneWidget);
    expect(find.text('New place'), findsNothing);
  });
}
