import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app.dart' show muted;
import '../core/widgets.dart';

const _streetViewSpots = [
  _ViewSpot('Hoan Kiem Lake — Huc Bridge',
      'https://maps.google.com/maps?q=Hoan+Kiem+Lake,+Hanoi&layer=c&cbll=21.0286,105.8524',
      Icons.water_outlined),
  _ViewSpot('Temple of Literature — Main Gate',
      'https://maps.google.com/maps?q=Temple+of+Literature,+Hanoi&layer=c&cbll=21.0286,105.8355',
      Icons.temple_buddhist_outlined),
  _ViewSpot('Old Quarter — Hàng Đào Street',
      'https://maps.google.com/maps?q=Hang+Dao,+Hoan+Kiem,+Hanoi&layer=c&cbll=21.0348,105.8483',
      Icons.storefront_outlined),
  _ViewSpot('Ho Chi Minh Mausoleum — Ba Dinh Square',
      'https://maps.google.com/maps?q=Ho+Chi+Minh+Mausoleum,+Hanoi&layer=c&cbll=21.0366,105.8342',
      Icons.account_balance_outlined),
];

class _ViewSpot {
  final String name, url;
  final IconData icon;
  const _ViewSpot(this.name, this.url, this.icon);
}

class VR360Page extends StatelessWidget {
  const VR360Page({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Walk before you arrive',
          title: 'VR360 exploration.',
          subtitle: 'Street-level views of Hanoi\'s landmarks — explore before you visit.',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.view_in_ar_outlined, color: Color(0xFF4A148C)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Full in-app VR360 navigation is coming soon. For now, tap any location below to open Google Street View in your browser.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4A148C)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Explore on Street View', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final spot in _streetViewSpots)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E7DF)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(spot.icon, color: const Color(0xFF4A148C), size: 22),
              ),
              title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: const Icon(Icons.open_in_new, size: 18, color: muted),
              onTap: () => launchUrl(Uri.parse(spot.url), mode: LaunchMode.externalApplication),
            ),
          ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF4A148C).withValues(alpha: 0.08), const Color(0xFF7B1FA2).withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.view_in_ar_outlined, color: Color(0xFF4A148C), size: 32),
              const SizedBox(height: 14),
              Text('Coming in a future version', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Planned VR360 features:\n• In-app immersive 360° panoramas\n• Guided virtual walking routes\n• Linked to real place details and phrasebook\n• Works offline with downloaded content',
                style: TextStyle(height: 1.7, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
