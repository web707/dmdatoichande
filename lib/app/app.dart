import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/store.dart';
import '../features/browse.dart';
import '../features/forms.dart';
import '../features/map_page.dart';
import '../features/admin.dart';
import '../features/events_page.dart';
import '../features/emergency_page.dart';
import '../features/more_page.dart';
import '../features/converter_page.dart';
import '../features/weather_page.dart';
import '../features/itinerary_page.dart';
import '../features/vr360_page.dart';

const ink = Color(0xFF173E35);
const paper = Color(0xFFF7F7F2);
const muted = Color(0xFF6E7A72);
const accent = Color(0xFFC9714B);

class HanoiApp extends StatefulWidget {
  final String initialLocation;
  const HanoiApp({super.key, this.initialLocation = '/places'});
  @override
  State<HanoiApp> createState() => _HanoiAppState();
}

class _HanoiAppState extends State<HanoiApp> {
  late final router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/places'),
      ShellRoute(
        builder: (context, state, child) =>
            GuideShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/places', builder: (_, _) => const PlacesPage()),
          GoRoute(path: '/phrases', builder: (_, _) => const PhrasebookPage()),
          GoRoute(
            path: '/saved',
            builder: (_, _) => const PhrasebookPage(savedOnly: true),
          ),
          GoRoute(path: '/food', builder: (_, _) => const FoodPage()),
          GoRoute(path: '/admin', builder: (_, _) => const AdminPage()),
          GoRoute(
            path: '/detail/:collection/:id',
            builder: (_, state) => DetailPage(
              collection: state.pathParameters['collection']!,
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/map/:collection/:id',
            builder: (_, state) => MapPage(
              collection: state.pathParameters['collection']!,
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/events', builder: (_, _) => const EventsPage()),
          GoRoute(path: '/emergency', builder: (_, _) => const EmergencyPage()),
          GoRoute(path: '/more', builder: (_, _) => const MorePage()),
          GoRoute(
            path: '/tools/converter',
            builder: (_, _) => const ConverterPage(),
          ),
          GoRoute(
            path: '/tools/weather',
            builder: (_, _) => const WeatherPage(),
          ),
          GoRoute(
            path: '/tools/itinerary',
            builder: (_, _) => const ItineraryPage(),
          ),
          GoRoute(path: '/tools/vr360', builder: (_, _) => const VR360Page()),
        ],
      ),
    ],
  );
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Hanoi, a little closer',
    debugShowCheckedModeBanner: false,
    routerConfig: router,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        surface: Colors.white,
        secondary: accent,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.65, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.55, color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE3DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE3DC)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: const BorderSide(color: Color(0xFFDCE3DC)),
      ),
      dividerColor: const Color(0xFFE1E7DF),
    ),
  );
}

class GuideShell extends ConsumerStatefulWidget {
  final String location;
  final Widget child;
  const GuideShell({super.key, required this.location, required this.child});
  @override
  ConsumerState<GuideShell> createState() => _GuideShellState();
}

class _GuideShellState extends ConsumerState<GuideShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(guideProvider).refresh();
  }

  static const destinations = [
    ('/places', 'Explore Hanoi', Icons.explore_outlined),
    ('/phrases', 'Phrasebook', Icons.chat_bubble_outline_rounded),
    ('/food', 'Food & cafés', Icons.ramen_dining_rounded),
    ('/events', 'Events', Icons.celebration_outlined),
    ('/more', 'More', Icons.apps_rounded),
  ];
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(guideProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final selected = destinations.indexWhere(
      (item) => widget.location == item.$1,
    );
    final header = Row(
      children: [
        const Icon(Icons.spa_outlined, color: ink, size: 28),
        const SizedBox(width: 9),
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'hanoi.',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                color: ink,
              ),
            ),
          ),
        ),
        if (!wide) ...[
          const Spacer(),
          IconButton(
            tooltip: 'Content studio',
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.edit_note_rounded),
          ),
        ],
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Container(
                width: 234,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: Color(0xFFE1E7DF))),
                ),
                padding: const EdgeInsets.fromLTRB(24, 34, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 3),
                    const Text(
                      'YOUR LOCAL COMPANION',
                      style: TextStyle(
                        fontSize: 9,
                        color: muted,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in destinations)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _NavItem(
                                  label: item.$2,
                                  icon: item.$3,
                                  selected: widget.location == item.$1,
                                  onTap: () => context.go(item.$1),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _NavItem(
                                label: 'Events & Festivals',
                                icon: Icons.celebration_outlined,
                                selected: widget.location == '/events',
                                onTap: () => context.go('/events'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _NavItem(
                                label: 'Emergency',
                                icon: Icons.emergency_outlined,
                                selected: widget.location == '/emergency',
                                onTap: () => context.go('/emergency'),
                                danger: true,
                              ),
                            ),
                            const Divider(height: 24),
                            const Padding(
                              padding: EdgeInsets.only(left: 14, bottom: 8),
                              child: Text('TOOLS', style: TextStyle(fontSize: 9, color: muted, letterSpacing: 2)),
                            ),
                            for (final item in [
                              ('/tools/converter', 'Currency converter', Icons.currency_exchange_rounded),
                              ('/tools/weather', 'Weather guide', Icons.wb_cloudy_outlined),
                              ('/tools/itinerary', 'Itinerary planner', Icons.map_outlined),
                              ('/tools/vr360', 'VR360 exploration', Icons.view_in_ar_outlined),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _NavItem(
                                  label: item.$2,
                                  icon: item.$3,
                                  selected: widget.location == item.$1,
                                  onTap: () => context.go(item.$1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: paper,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.wb_sunny_outlined, color: accent),
                          SizedBox(height: 10),
                          Text(
                            'Go slow. Look closer.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'The best of Hanoi is often found between the landmarks.',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _NavItem(
                      label: 'Content studio',
                      icon: Icons.edit_note_rounded,
                      selected: widget.location == '/admin',
                      onTap: () => context.go('/admin'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 82,
                    padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE1E7DF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (wide)
                          const Text(
                            'HANOI, VIETNAM',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          )
                        else
                          Expanded(child: header),
                        if (wide) const Spacer(),
                        if (wide) ...[
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: store.live && store.error == null
                                ? const Color(0xFF428961)
                                : accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            store.error != null
                                ? 'Connection interrupted'
                                : store.live
                                ? 'Live updates'
                                : 'Connecting',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                          const SizedBox(width: 20),
                        ],
                        IconButton(
                          tooltip: 'Refresh guide',
                          onPressed: () => store.refresh(),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                        ),
                        TextButton.icon(
                          onPressed: () => showAccountDialog(context, store),
                          icon: const Icon(
                            Icons.account_circle_outlined,
                            size: 20,
                          ),
                          label: Text(
                            store.user == null
                                ? 'Sign in'
                                : store.isAdmin
                                ? 'Admin'
                                : 'Account',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (store.error != null)
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFFFEEDC),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${store.error!}${store.lastSync == null ? '' : ' Showing the last loaded guide.'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: store.refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected < 0 ? 0 : selected,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].$1),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Icon(item.$3),
                    label: switch (item.$1) {
                      '/places' => 'Explore',
                      '/food' => 'Food',
                      '/events' => 'Events',
                      '/more' => 'More',
                      _ => 'Phrasebook',
                    },
                  ),
              ],
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool danger;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE8EFE7) : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color:
                  danger
                      ? const Color(0xFFB22222)
                      : (selected ? ink : muted),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      danger
                          ? const Color(0xFFB22222)
                          : (selected ? ink : muted),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
