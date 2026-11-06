import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/store.dart';
import '../core/widgets.dart';
import '../app/app.dart' show muted;
import 'forms.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});
  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  String collection = 'places';
  String query = '';
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(guideProvider);
    if (!store.isAdmin) {
      return PageBody(
        children: [
          const SectionHeading(
            eyebrow: 'Content studio',
            title: 'Administrator access',
            subtitle: 'Sign in with an administrator account to edit the shared city guide.',
          ),
          FilledButton.icon(
            onPressed: () => showAccountDialog(context, store),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Sign in'),
          ),
        ],
      );
    }
    final rows = store
        .list(collection)
        .where((item) => item.matches(query) && !item.isPrivate)
        .toList();
    return PageBody(
      children: [
        SectionHeading(
          eyebrow: 'Content studio',
          title: 'Keep Hanoi up to date.',
          subtitle:
              'Changes appear automatically on connected Web and Mobile apps.',
          action: FilledButton.icon(
            onPressed: () => showRecordEditor(context, store, collection),
            icon: const Icon(Icons.add),
            label: Text(switch (collection) {
              'places' => 'New place',
              'phrases' => 'New shared phrase',
              _ => 'New restaurant',
            }),
          ),
        ),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final item in [
              ('places', 'Places'),
              ('phrases', 'Phrases'),
              ('foods_restaurants', 'Food & restaurants'),
            ])
              ChoiceChip(
                label: Text(item.$2),
                selected: collection == item.$1,
                onSelected: (_) => setState(() => collection = item.$1),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SearchBox(
          hint: 'Search this collection',
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 22),
        Text(
          '${rows.length} records · Changes are saved to PostgreSQL',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const EmptyState(
            'No records here yet',
            'Add a record to start building your guide.',
          ),
        for (final record in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  collection == 'foods_restaurants'
                      ? '${record.text('restaurant_name')} · ${record.text('address')}'
                      : record.subtitle,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => showRecordEditor(
                        context,
                        store,
                        collection,
                        record: record,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                    if (collection != 'phrases')
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/map/$collection/${record.id}'),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Check map'),
                      ),
                    TextButton.icon(
                      onPressed: () => confirmDelete(context, store, record),
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
