import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../app/app.dart' show ink, muted, accent;
import '../core/catalog.dart';
import '../core/store.dart';
import '../core/widgets.dart';
import 'forms.dart';

class PlacesPage extends ConsumerStatefulWidget {
  const PlacesPage({super.key});
  @override
  ConsumerState<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends ConsumerState<PlacesPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(guideProvider);
    final places = store
        .list('places')
        .where((item) => item.matches(query))
        .toList();
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'A city worth getting to know',
          title: 'Welcome to Hanoi.',
          subtitle: 'Ancient stories. Everyday discoveries. Your journey starts here.',
        ),
        Container(
          height: 260,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/hoan_kiem.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, .25),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xEA143A31), Color(0x20143A31)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'HISTORY AROUND EVERY CORNER',
                      style: TextStyle(
                        color: Color(0xFFDDE8BF),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'A little closer\nto Hanoi.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 39,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Start by the lake. Let the city unfold.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Photo: Cyril Doussin · CC BY-SA 2.0',
                      style: TextStyle(color: Color(0xFFCED7CC), fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 27),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _QuickLink(
              Icons.temple_buddhist_outlined,
              '${store.list('places').length} places to explore',
              () {},
            ),
            _QuickLink(
              Icons.chat_bubble_outline,
              '${store.list('phrases').length} useful phrases',
              () => context.go('/phrases'),
            ),
            _QuickLink(
              Icons.ramen_dining,
              '${groupFoods(store.list('foods_restaurants')).length} local flavours',
              () => context.go('/food'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Discover the city',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Meet the places that make Hanoi, Hanoi.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        SearchBox(
          hint: 'Search places, names or addresses',
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 22),
        if (store.loading)
          const Center(child: CircularProgressIndicator())
        else if (places.isEmpty)
          const EmptyState(
            'No places found',
            'Try a different search or refresh your guide.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 740 ? 2 : 1;
              final width = (constraints.maxWidth - 22 * (count - 1)) / count;
              return Wrap(
                spacing: 22,
                runSpacing: 22,
                children: [
                  for (final place in places)
                    SizedBox(width: width, child: _PlaceCard(place)),
                ],
              );
            },
          ),
        const SizedBox(height: 30),
        const Text(
          'Made for curious travellers. Explore thoughtfully, and leave places as you found them.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => ActionChip(
    onPressed: onTap,
    backgroundColor: Colors.white,
    avatar: Icon(icon, size: 17, color: ink),
    label: Text(label, style: const TextStyle(fontSize: 12)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
  );
}

class _PlaceCard extends StatelessWidget {
  final CatalogRecord place;
  const _PlaceCard(this.place);
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE1E7DF)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/detail/places/${place.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlaceImage(place),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HISTORY & CULTURE',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  place.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 3),
                Text(
                  place.subtitle,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 12),
                Text(
                  place.text('summary_en'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Discover this place',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'View on map',
                      onPressed: () => context.push('/map/places/${place.id}'),
                      icon: const Icon(Icons.arrow_outward, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PhrasebookPage extends ConsumerStatefulWidget {
  final bool savedOnly;
  const PhrasebookPage({super.key, this.savedOnly = false});
  @override
  ConsumerState<PhrasebookPage> createState() => _PhrasebookPageState();
}

class _PhrasebookPageState extends ConsumerState<PhrasebookPage> {
  String query = '';
  String category = 'all';
  final tts = FlutterTts();
  Future<void> speak(CatalogRecord phrase) async {
    try {
      final available = await tts.isLanguageAvailable('vi-VN');
      if (available != true && available != 1) {
        if (mounted) {
          showMessage(
            context,
            'Vietnamese voice is not available on this device. Use the pronunciation guide below.',
          );
        }
        return;
      }
      await tts.stop();
      await tts.setLanguage('vi-VN');
      await tts.setSpeechRate(.42);
      await tts.speak(phrase.title);
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Audio is unavailable. The pronunciation guide is still available.',
        );
      }
    }
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(guideProvider);
    final phrases = store
        .list('phrases')
        .where(
          (item) =>
              item.matches(query) &&
              (category == 'all' || item.text('category') == category) &&
              (!widget.savedOnly || store.favorites.contains(item.id)),
        )
        .toList();
    return PageBody(
      children: [
        SectionHeading(
          eyebrow: widget.savedOnly
              ? 'Keep the words you need'
              : 'A few words go a long way',
          title: widget.savedOnly
              ? 'Your saved phrases.'
              : 'Say it in Vietnamese.',
          subtitle: widget.savedOnly ? 'Your bookmarks stay on this device.' : 'A little Vietnamese can turn a simple moment into a connection.',
          action: FilledButton.icon(
            onPressed: () async {
              if (store.user == null) {
                await showAccountDialog(context, store);
                if (!context.mounted || store.user == null) return;
              }
              if (context.mounted) {
                await showRecordEditor(context, store, 'phrases');
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(store.isAdmin ? 'Add shared phrase' : 'Add my phrase'),
          ),
        ),
        SearchBox(
          hint: 'Search in English or Vietnamese',
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in [
              'all',
              'greetings',
              'shopping',
              'food',
              'directions',
              'other',
            ])
              ChoiceChip(
                label: Text(value[0].toUpperCase() + value.substring(1)),
                selected: category == value,
                onSelected: (_) => setState(() => category = value),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Pronunciation is approximate; Vietnamese tones are best learned by listening. Audio availability depends on your device.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 22),
        if (store.loading)
          const Center(child: CircularProgressIndicator())
        else if (phrases.isEmpty)
          const EmptyState(
            'No matching phrases',
            'Try another search, or save a phrase from the phrasebook.',
          )
        else
          for (final phrase in phrases)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1E7DF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${phrase.text('category').toUpperCase()}${phrase.isPrivate ? ' · ONLY YOU' : ''}',
                              style: const TextStyle(
                                color: accent,
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            SelectionArea(
                              child: Text(
                                phrase.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(phrase.subtitle),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: store.favorites.contains(phrase.id)
                            ? 'Unsave phrase'
                            : 'Save phrase',
                        onPressed: () async {
                          try {
                            await store.toggleFavorite(phrase.id);
                          } catch (error) {
                            if (context.mounted) {
                              showMessage(context, error.toString());
                            }
                          }
                        },
                        icon: Icon(
                          store.favorites.contains(phrase.id)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Listen in Vietnamese',
                        onPressed: () => speak(phrase),
                        icon: const Icon(Icons.volume_up_outlined, size: 20),
                      ),
                      Text(
                        phrase.text('pronunciation_guide'),
                        style: const TextStyle(
                          color: muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (phrase.text('ipa').isNotEmpty)
                        Text('/${phrase.text('ipa')}/'),
                    ],
                  ),
                  if (phrase.text('usage_note_en').isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      phrase.text('usage_note_en'),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                  if (phrase.isPrivate &&
                      phrase.text('owner_id') == store.user?['id'])
                    Wrap(
                      children: [
                        TextButton.icon(
                          onPressed: () => showRecordEditor(
                            context,
                            store,
                            'phrases',
                            record: phrase,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              confirmDelete(context, store, phrase),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class FoodPage extends ConsumerStatefulWidget {
  const FoodPage({super.key});
  @override
  ConsumerState<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends ConsumerState<FoodPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(guideProvider);
    final groups = groupFoods(
      store
          .list('foods_restaurants')
          .where((item) => item.matches(query))
          .toList(),
    );
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Pull up a little plastic chair',
          title: 'Taste the real Hanoi.',
          subtitle: 'The dishes to know, and the neighbourhood spots that serve them.',
        ),
        SearchBox(
          hint: 'Try “pho”, “bun cha” or a restaurant name',
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 24),
        if (store.loading)
          const Center(child: CircularProgressIndicator())
        else if (groups.isEmpty)
          const EmptyState(
            'No dishes found',
            'Try a dish name without accents, or search an address.',
          )
        else
          for (final group in groups.values)
            Container(
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE1E7DF)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.first.text('image_url').isNotEmpty)
                    PlaceImage(group.first),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAEDE2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.ramen_dining,
                                color: accent,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 17),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.first.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  Text(
                                    group.first.subtitle,
                                    style: const TextStyle(color: muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(group.first.text('description_en')),
                        const SizedBox(height: 22),
                        Text(
                          'WHERE TO TRY IT · ${group.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: muted,
                            letterSpacing: 1.7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final restaurant in group)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.text('restaurant_name'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        restaurant.text('address'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: muted,
                                        ),
                                      ),
                                      Wrap(
                                        spacing: 10,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => context.push(
                                              '/map/foods_restaurants/${restaurant.id}',
                                            ),
                                            icon: const Icon(
                                              Icons.map_outlined,
                                              size: 17,
                                            ),
                                            label: const Text('View on map'),
                                          ),
                                          if (restaurant
                                              .text('source_url')
                                              .isNotEmpty)
                                            SourceLink(
                                              restaurant.text('source_url'),
                                              label: 'Restaurant source',
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        const Text(
          'Addresses are provided for discovery. Check opening hours directly with the restaurant before visiting.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }
}

class DetailPage extends ConsumerWidget {
  final String collection, id;
  const DetailPage({super.key, required this.collection, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(guideProvider);
    final record = store.find(collection, id);
    if (store.loading) return const Center(child: CircularProgressIndicator());
    if (record == null) {
      return const EmptyState(
        'This item is no longer available',
        'It may have been removed. Return to Explore to discover another place.',
      );
    }
    return PageBody(
      children: [
        TextButton.icon(
          onPressed: () => context.go('/places'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to explore'),
        ),
        const SizedBox(height: 12),
        SectionHeading(
          eyebrow: record.subtitle,
          title: record.title,
          subtitle: record.text('address'),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: PlaceImage(
            record,
            height: MediaQuery.sizeOf(context).width < 600 ? 220 : 340,
          ),
        ),
        const SizedBox(height: 8),
        SelectionArea(
          child: Text(
            record.text('image_credit'),
            style: const TextStyle(fontSize: 10, color: muted),
          ),
        ),
        const SizedBox(height: 24),
        Text('The story', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          record.text('history_en'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 26),
        Text(
          'Culture & everyday life',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          record.text('culture_en'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        SelectionArea(
          child: Text(
            'Latitude ${record.latitude.toStringAsFixed(6)} · Longitude ${record.longitude.toStringAsFixed(6)}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/map/$collection/$id'),
          icon: const Icon(Icons.map_outlined),
          label: const Text('View on map'),
        ),
        // Visit info section
        if (record.text('opening_hours').isNotEmpty || record.text('booking_info').isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Visit information', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (record.text('opening_hours').isNotEmpty)
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Opening hours',
              value: record.text('opening_hours'),
            ),
          if (record.text('best_time_to_visit').isNotEmpty)
            _InfoRow(
              icon: Icons.wb_sunny_outlined,
              label: 'Best time to visit',
              value: record.text('best_time_to_visit'),
            ),
          _TicketPriceRow(record),
          if (record.text('visit_duration_min').isNotEmpty && record.text('visit_duration_min') != '0')
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Suggested duration',
              value: '${record.text('visit_duration_min')} minutes',
            ),
          if (record.text('booking_info').isNotEmpty)
            _InfoRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Tickets & booking',
              value: record.text('booking_info'),
            ),
        ],
        if (record.text('source_url').isNotEmpty) ...[
          const SizedBox(height: 18),
          SourceLink(record.text('source_url')),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: muted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              SelectionArea(child: Text(value)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TicketPriceRow extends StatelessWidget {
  final CatalogRecord record;
  const _TicketPriceRow(this.record);
  @override
  Widget build(BuildContext context) {
    final vnd = int.tryParse(record.text('ticket_price_vnd')) ?? 0;
    final usd = double.tryParse(record.text('ticket_price_usd')) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_activity_outlined, size: 20, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admission', style: TextStyle(fontSize: 11, color: muted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                vnd == 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Free entry', style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.w700)),
                      )
                    : Text('${_formatVnd(vnd)} VND  ·  ~\$${usd.toStringAsFixed(2)} USD'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _formatVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
