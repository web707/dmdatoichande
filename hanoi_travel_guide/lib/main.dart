import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api.dart';
import 'core/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = GuideStore(GuideApi(), await SharedPreferences.getInstance())
    ..start();
  runApp(
    ProviderScope(
      overrides: [guideProvider.overrideWith((ref) => store)],
      child: const HanoiApp(),
    ),
  );
}
