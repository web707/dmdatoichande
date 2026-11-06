import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app.dart' show ink, muted, paper;
import '../core/store.dart';
import '../core/widgets.dart';

const _emergencyRed = Color(0xFFB22222);

// Hardcoded fallback critical numbers (shown even if API unavailable)
const _criticalNumbers = [
  {'name': 'Police', 'name_vi': 'Cảnh sát', 'phone': '113', 'icon': Icons.local_police_outlined},
  {'name': 'Fire Brigade', 'name_vi': 'Cứu hỏa', 'phone': '114', 'icon': Icons.local_fire_department_outlined},
  {'name': 'Ambulance', 'name_vi': 'Cấp cứu', 'phone': '115', 'icon': Icons.local_hospital_outlined},
];

class EmergencyPage extends ConsumerWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(guideProvider);
    final contacts = store.emergencyContacts;

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final c in contacts) {
      final cat = c['category']?.toString() ?? 'other';
      grouped.putIfAbsent(cat, () => []).add(c);
    }

    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Stay safe in Hanoi',
          title: 'Emergency support.',
          subtitle: 'Important numbers and locations for police, medical care, and your embassy.',
        ),
        // Critical numbers — always visible
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFCCCC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _emergencyRed, size: 22),
                  SizedBox(width: 10),
                  Text('Emergency numbers — Vietnam',
                      style: TextStyle(fontWeight: FontWeight.w700, color: _emergencyRed)),
                ],
              ),
              const SizedBox(height: 16),
              for (final item in _criticalNumbers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(item['icon'] as IconData, color: _emergencyRed, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            Text(item['name_vi'] as String,
                                style: const TextStyle(color: muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: _emergencyRed),
                        onPressed: () => _call(item['phone'] as String),
                        icon: const Icon(Icons.phone, size: 16),
                        label: Text(item['phone'] as String,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // API-loaded sections
        if (contacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: paper,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: muted),
                SizedBox(width: 10),
                Expanded(child: Text('Connect to the guide server to load hospitals, pharmacies and embassies.',
                    style: TextStyle(color: muted, fontSize: 13))),
              ],
            ),
          )
        else ...[
          _ContactSection(
            title: 'Hospitals',
            icon: Icons.local_hospital_outlined,
            contacts: grouped['hospital'] ?? [],
          ),
          _ContactSection(
            title: 'Pharmacies',
            icon: Icons.local_pharmacy_outlined,
            contacts: grouped['pharmacy'] ?? [],
          ),
          _ContactSection(
            title: 'Embassies',
            icon: Icons.flag_outlined,
            contacts: grouped['embassy'] ?? [],
          ),
          _ContactSection(
            title: 'Tourist Police',
            icon: Icons.support_agent_outlined,
            contacts: grouped['police']?.where((c) => c['phone'] != '113').toList() ?? [],
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'In a life-threatening emergency dial 113 (police), 114 (fire) or 115 (ambulance). These numbers work from any phone in Vietnam.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  void _call(String phone) {
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '');
    launchUrl(Uri.parse('tel:$cleaned'));
  }
}

class _ContactSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> contacts;
  const _ContactSection({required this.title, required this.icon, required this.contacts});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: ink),
            const SizedBox(width: 10),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 14),
        for (final c in contacts)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['name_en']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if ((c['address']?.toString() ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(c['address']!.toString(),
                        style: const TextStyle(color: muted, fontSize: 12)),
                  ),
                if ((c['note_en']?.toString() ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(c['note_en']!.toString(),
                        style: const TextStyle(color: muted, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if ((c['phone']?.toString() ?? '').isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          final p = (c['phone'] as String).replaceAll(' ', '');
                          launchUrl(Uri.parse('tel:$p'));
                        },
                        icon: const Icon(Icons.phone, size: 16),
                        label: Text(c['phone']!.toString()),
                      ),
                    if (c['latitude'] != null && c['longitude'] != null)
                      TextButton.icon(
                        onPressed: () {
                          // navigate to a simple map view using existing MapPage pattern
                          // We pass coords via query params or encode in URL
                          final lat = c['latitude'];
                          final lon = c['longitude'];
                          launchUrl(Uri.parse(
                            'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon',
                          ));
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('View on map'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
