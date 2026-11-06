import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/app.dart' show ink, muted, accent;
import '../core/catalog.dart';
import '../core/store.dart';
import '../core/widgets.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});
  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  String query = '';
  String filter = 'all'; // 'all', 'recurring', 'dated'

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(guideProvider);
    final allEvents = store.list('events');
    final filtered = allEvents.where((e) {
      final matchesQuery = e.matches(query);
      final isRecurring = e.text('is_recurring') == 'true';
      final matchesFilter = filter == 'all' ||
          (filter == 'recurring' && isRecurring) ||
          (filter == 'dated' && !isRecurring);
      return matchesQuery && matchesFilter;
    }).toList();

    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Culture, tradition and celebration',
          title: 'Events & Festivals.',
          subtitle: 'From ancient lunar ceremonies to weekly night markets — Hanoi has something happening year-round.',
        ),
        SearchBox(
          hint: 'Search events and festivals',
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final item in [('all', 'All'), ('recurring', 'Recurring'), ('dated', 'Fixed date')])
              ChoiceChip(
                label: Text(item.$2),
                selected: filter == item.$1,
                onSelected: (_) => setState(() => filter = item.$1),
              ),
          ],
        ),
        const SizedBox(height: 22),
        if (store.loading)
          const Center(child: CircularProgressIndicator())
        else if (filtered.isEmpty)
          const EmptyState('No events found', 'Try a different search or filter.')
        else
          for (final event in filtered) _EventCard(event),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final CatalogRecord event;
  const _EventCard(this.event);

  @override
  Widget build(BuildContext context) {
    final isRecurring = event.text('is_recurring') == 'true';
    final recurrence = event.text('recurrence_note');
    final dateStart = event.text('event_date_start');
    final dateEnd = event.text('event_date_end');
    final locationName = event.text('location_name');
    final dateDisplay = isRecurring
        ? recurrence
        : [dateStart, if (dateEnd.isNotEmpty && dateEnd != dateStart) dateEnd].where((s) => s.isNotEmpty).join(' – ');

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7DF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRecurring ? const Color(0xFFE8F0E8) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRecurring ? 'Recurring' : 'Annual',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isRecurring ? ink : accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.celebration_outlined, color: accent, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Text(event.title, style: Theme.of(context).textTheme.titleLarge),
            Text(event.subtitle, style: const TextStyle(color: muted)),
            const SizedBox(height: 12),
            Text(event.text('description_en'), style: const TextStyle(height: 1.6)),
            if (dateDisplay.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.event_outlined, size: 18, color: muted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(dateDisplay, style: const TextStyle(color: muted, fontSize: 13))),
                ],
              ),
            ],
            if (locationName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 18, color: muted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(locationName, style: const TextStyle(color: muted, fontSize: 13))),
                ],
              ),
            ],
            if (event.hasLocation) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => context.push('/map/events/${event.id}'),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('View on map'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
