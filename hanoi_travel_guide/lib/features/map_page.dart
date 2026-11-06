import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app.dart' show ink, muted, accent;
import '../core/store.dart';
import '../core/widgets.dart';

class MapPage extends ConsumerWidget {
  final String collection, id;
  const MapPage({super.key, required this.collection, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(guideProvider);
    final record = store.find(collection, id);
    if (record != null && !record.hasLocation) {
      return const EmptyState(
        'No map location',
        'This item does not have a map location associated with it.',
      );
    }
    if (store.loading) return const Center(child: CircularProgressIndicator());
    if (record == null) {
      return const EmptyState(
        'This item is no longer available',
        'Return to the guide to choose another location.',
      );
    }
    final title = collection == 'foods_restaurants'
        ? record.text('restaurant_name')
        : record.title;
    final point = LatLng(record.latitude, record.longitude);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go(
              collection == 'places'
                  ? '/places'
                  : (collection == 'events' ? '/events' : '/food'),
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to guide'),
          ),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 7),
          Text(record.text('address'), style: const TextStyle(color: muted)),
          const SizedBox(height: 8),
          SelectionArea(
            child: Text(
              'Latitude ${record.latitude.toStringAsFixed(6)} · Longitude ${record.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                key: ValueKey('$id:${record.latitude}:${record.longitude}'),
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 16,
                  minZoom: 3,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'vn.hanoiguide.hanoi_travel_guide',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 54,
                        height: 64,
                        alignment: Alignment.topCenter,
                        child: Tooltip(
                          message: title,
                          child: const Icon(
                            Icons.location_on,
                            color: accent,
                            size: 54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SimpleAttributionWidget(
                    source: const Text(
                      'OpenStreetMap contributors',
                      style: TextStyle(fontSize: 11),
                    ),
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 15, color: ink),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pinch or scroll to zoom. Map tiles need an internet connection.',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
