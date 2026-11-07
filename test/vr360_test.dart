import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hanoi_travel_guide/features/vr360_tour.dart';

import 'features_test.dart' show mount, tap;

void main() {
  test('the bundled PDC tour has usable panoramas, links and narration', () {
    final tour = jsonDecode(
      File('assets/vr360/tour.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final scenes = (tour['scenes'] as List).cast<Map<String, dynamic>>();
    final ids = scenes.map((scene) => scene['id']).toSet();
    expect(scenes, hasLength(15));
    expect(ids, hasLength(15));
    expect(ids, contains(tour['entrySceneId']));
    final links = <Object?, List<dynamic>>{
      for (final scene in scenes) scene['id']: scene['links'] as List,
    };
    final reached = <Object?>{};
    final pending = <Object?>[tour['entrySceneId']];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      if (reached.add(id)) {
        pending.addAll(links[id]!.map((link) => link['targetId']));
      }
    }
    expect(reached, equals(ids));
    for (final scene in scenes) {
      expect(
        File('assets/vr360/${scene['image']}').lengthSync(),
        greaterThan(0),
      );
      for (final link in scene['links'] as List) {
        expect(ids, contains(link['targetId']));
      }
      final audio = scene['audio'] as Map;
      if (audio.isEmpty) continue;
      expect(audio.keys, unorderedEquals(['en', 'vi']));
      for (final path in audio.values) {
        expect(File('assets/vr360/$path').lengthSync(), greaterThan(0));
      }
    }
  });

  testWidgets('VR360 opens the guided tour from the More menu', (tester) async {
    await mount(tester, '/more');
    await tap(tester, find.text('VR360'));
    final start = find.text('Start 360° tour');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    expect(find.byType(VR360TourPage), findsOneWidget);
  });
}
