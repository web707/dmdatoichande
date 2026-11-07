import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanoi_travel_guide/core/widgets.dart';

import 'features_test.dart' show mount, tap;

void main() {
  testWidgets('lake detail opens the embedded tour at the aerial scene', (
    tester,
  ) async {
    await mount(tester, '/detail/places/10000000-0000-4000-8000-000000000001');
    await tap(tester, find.text('Explore in VR360'));
    expect(find.text('Hoan Kiem Lake in 360°'), findsOneWidget);
    expect(find.byKey(const ValueKey('hoan-kiem-tour-viewer')), findsOneWidget);
    expect(
      tester.widget<SourceLink>(find.byType(SourceLink)).url,
      endsWith('?room=9861'),
    );

    await tap(tester, find.text('All 14 scenes'));
    await tap(tester, find.text('The Huc Bridge'));
    expect(find.byKey(const ValueKey('hoan-kiem-tour-viewer')), findsOneWidget);
    expect(
      tester.widget<SourceLink>(find.byType(SourceLink)).url,
      endsWith('?room=9860'),
    );

    await tap(tester, find.text('All 14 scenes'));
    expect(find.textContaining('red wooden bridge'), findsOneWidget);
  });

  testWidgets(
    'the VR360 hub offers the lake tour alongside the existing tour',
    (tester) async {
      await mount(tester, '/tools/vr360');
      expect(find.text('Start 360° tour'), findsOneWidget);
      await tap(tester, find.text('Explore in VR360'));
      expect(find.text('Hoan Kiem Lake in 360°'), findsOneWidget);
    },
  );

  testWidgets('other places do not link to the lake tour', (tester) async {
    await mount(tester, '/detail/places/10000000-0000-4000-8000-000000000002');
    expect(find.text('Explore in VR360'), findsNothing);
  });
}
