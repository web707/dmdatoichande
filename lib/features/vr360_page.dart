import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app.dart' show muted;
import '../core/widgets.dart';
import 'hoan_kiem_vr360.dart';

const _streetViewSpots = [
  _ViewSpot(
    'Hoan Kiem Lake — Huc Bridge',
    'https://maps.google.com/maps?q=Hoan+Kiem+Lake,+Hanoi&layer=c&cbll=21.0286,105.8524',
    Icons.water_outlined,
  ),
  _ViewSpot(
    'Temple of Literature — Main Gate',
    'https://maps.google.com/maps?q=Temple+of+Literature,+Hanoi&layer=c&cbll=21.0286,105.8355',
    Icons.temple_buddhist_outlined,
  ),
  _ViewSpot(
    'Old Quarter — Hàng Đào Street',
    'https://maps.google.com/maps?q=Hang+Dao,+Hoan+Kiem,+Hanoi&layer=c&cbll=21.0348,105.8483',
    Icons.storefront_outlined,
  ),
  _ViewSpot(
    'Ho Chi Minh Mausoleum — Ba Dinh Square',
    'https://maps.google.com/maps?q=Ho+Chi+Minh+Mausoleum,+Hanoi&layer=c&cbll=21.0366,105.8342',
    Icons.account_balance_outlined,
  ),
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
          subtitle: 'Look around Hanoi’s heritage sites and follow the tour at your own pace.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoan Kiem Lake',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('14 scenes around the lake · Báo Nhân Dân'),
                const SizedBox(height: 12),
                const HoanKiemTourButton(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dinh Cong Thuong Communal House & Goldsmith Ancestors Temple',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Đình Định Công Thượng & Đền thờ Tổ nghề Kim hoàn'),
              const SizedBox(height: 8),
              const Text(
                '15 scenes · English and Vietnamese narration · Available offline',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.view_in_ar_outlined),
                label: const Text('Start 360° tour'),
                onPressed: () => context.go('/tools/vr360/tour'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Explore on Street View',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        for (final spot in _streetViewSpots)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E7DF)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    spot.icon,
                    color: const Color(0xFF4A148C),
                    size: 22,
                  ),
                ),
                title: Text(
                  spot.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, size: 18, color: muted),
                onTap: () => launchUrl(
                  Uri.parse(spot.url),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
