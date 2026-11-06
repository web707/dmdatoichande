import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/app.dart' show ink, muted, paper;
import '../core/catalog.dart';
import '../core/store.dart';
import '../core/widgets.dart';

enum _Style { culture, food, mix }

class ItineraryPage extends ConsumerStatefulWidget {
  const ItineraryPage({super.key});
  @override
  ConsumerState<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends ConsumerState<ItineraryPage> {
  int _days = 2;
  _Style _style = _Style.mix;
  List<_Day>? _plan;

  void _generate(GuideStore store) {
    final places = store.list('places');
    final foods = groupFoods(store.list('foods_restaurants'));
    final foodGroups = foods.values.toList();
    final plan = <_Day>[];
    final usedPlaces = <String>{};
    final usedFoods = <String>{};

    CatalogRecord? nextPlace() {
      for (final p in places) {
        if (!usedPlaces.contains(p.id)) { usedPlaces.add(p.id); return p; }
      }
      return places.isNotEmpty ? places.first : null;
    }

    List<CatalogRecord>? nextFood() {
      for (final g in foodGroups) {
        if (!usedFoods.contains(g.first.text('food_key'))) {
          usedFoods.add(g.first.text('food_key'));
          return g;
        }
      }
      return foodGroups.isNotEmpty ? foodGroups.first : null;
    }

    for (var d = 0; d < _days; d++) {
      final slots = <_Slot>[];

      // Morning
      if (_style != _Style.food) {
        final p = nextPlace();
        if (p != null) {
          slots.add(_Slot('Morning', Icons.wb_sunny_outlined,
              p.title, p.text('address'),
              hint: p.text('opening_hours').isNotEmpty ? p.text('opening_hours') : null,
              onTap: (ctx) => ctx.push('/detail/places/${p.id}')));
        }
      } else {
        final f = nextFood();
        if (f != null) {
          slots.add(_Slot('Breakfast', Icons.coffee_outlined,
              f.first.title, f.first.text('restaurant_name'),
              onTap: (ctx) => ctx.go('/food')));
        }
      }

      // Lunch
      final f1 = nextFood();
      if (f1 != null) {
        slots.add(_Slot('Lunch', Icons.restaurant_outlined,
            f1.first.title, f1.first.text('restaurant_name'),
            onTap: (ctx) => ctx.go('/food')));
      }

      // Afternoon
      if (_style != _Style.food) {
        final p2 = nextPlace();
        if (p2 != null) {
          slots.add(_Slot('Afternoon', Icons.explore_outlined,
              p2.title, p2.text('address'),
              hint: p2.text('best_time_to_visit').isNotEmpty ? p2.text('best_time_to_visit') : null,
              onTap: (ctx) => ctx.push('/detail/places/${p2.id}')));
        }
      }

      // Dinner
      final f2 = nextFood();
      if (f2 != null) {
        slots.add(_Slot('Dinner', Icons.dinner_dining_outlined,
            f2.first.title, f2.first.text('restaurant_name'),
            onTap: (ctx) => ctx.go('/food')));
      }

      plan.add(_Day(d + 1, slots));
    }
    setState(() => _plan = plan);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(guideProvider);
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Make the most of your time',
          title: 'Itinerary planner.',
          subtitle: 'Tell us how long you have and we\'ll suggest a day-by-day guide.',
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1E7DF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How many days?', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in [1, 2, 3, 4, 5])
                    ChoiceChip(
                      label: Text('$d day${d > 1 ? "s" : ""}'),
                      selected: _days == d,
                      onSelected: (_) => setState(() { _days = d; _plan = null; }),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('What interests you?', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final item in [(_Style.mix, 'Mix of everything'), (_Style.culture, 'Culture & history'), (_Style.food, 'Food & cafés')])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _style == item.$1,
                      onSelected: (_) => setState(() { _style = item.$1; _plan = null; }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _generate(store),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate my itinerary'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (_plan != null)
          for (final day in _plan!) ...[
            Text('Day ${day.number}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 14),
            for (final slot in day.slots)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E7DF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: paper,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(slot.icon, color: ink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot.time, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(slot.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(slot.detail, style: const TextStyle(color: muted, fontSize: 12)),
                          if (slot.hint != null) ...[
                            const SizedBox(height: 4),
                            Text(slot.hint!, style: const TextStyle(fontSize: 11, color: muted, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    if (slot.onTap != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        onPressed: () => slot.onTap!(context),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
          ],
        if (_plan != null)
          const Text(
            'This is a suggested itinerary. Adjust based on opening hours and your own pace. Some venues close on Mondays.',
            style: TextStyle(fontSize: 12, color: muted),
          ),
      ],
    );
  }
}

class _Day { final int number; final List<_Slot> slots; const _Day(this.number, this.slots); }
class _Slot {
  final String time, name, detail;
  final String? hint;
  final IconData icon;
  final void Function(BuildContext)? onTap;
  const _Slot(this.time, this.icon, this.name, this.detail, {this.hint, this.onTap});
}
