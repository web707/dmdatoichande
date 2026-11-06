import 'package:flutter/material.dart';
import '../app/app.dart' show muted, accent;
import '../core/widgets.dart';

const _months = [
  _MonthData('January', '17–23°C', 'Cool & dry', Icons.ac_unit),
  _MonthData('February', '17–24°C', 'Cool & dry, peach blossom', Icons.ac_unit),
  _MonthData('March', '19–27°C', 'Warm, drizzle', Icons.cloud_outlined),
  _MonthData('April', '23–31°C', 'Warm, occasional rain', Icons.cloud_outlined),
  _MonthData('May', '26–34°C', 'Hot, rain begins', Icons.thunderstorm_outlined),
  _MonthData('June', '28–35°C', 'Hot & humid, heavy rain', Icons.thunderstorm_outlined),
  _MonthData('July', '28–34°C', 'Peak heat, heavy rain', Icons.thunderstorm_outlined),
  _MonthData('August', '27–33°C', 'Hot, heaviest rain', Icons.thunderstorm_outlined),
  _MonthData('September', '25–31°C', 'Warm, rain easing', Icons.cloud_outlined),
  _MonthData('October', '22–28°C', 'Pleasant, some rain', Icons.wb_sunny_outlined),
  _MonthData('November', '19–25°C', 'Cool & pleasant', Icons.wb_sunny_outlined),
  _MonthData('December', '16–21°C', 'Cool & dry', Icons.ac_unit),
];

const _packingTips = [
  _PackingTip('Nov – Feb\n(Cool & dry)',
      Icons.checkroom,
      ['Light jacket or cardigan', 'Long trousers', 'Closed shoes', 'Layer up for mornings']),
  _PackingTip('Mar – Apr\n(Warm)',
      Icons.wb_sunny_outlined,
      ['Light layers', 'Comfortable walking shoes', 'Small umbrella', 'Sunscreen SPF 50+']),
  _PackingTip('May – Oct\n(Hot & rainy)',
      Icons.umbrella,
      ['Light breathable clothing', 'Rain jacket or poncho', 'Waterproof sandals', 'Mosquito repellent']),
];

class _MonthData {
  final String name, temp, desc;
  final IconData icon;
  const _MonthData(this.name, this.temp, this.desc, this.icon);
}

class _PackingTip {
  final String season;
  final IconData icon;
  final List<String> items;
  const _PackingTip(this.season, this.icon, this.items);
}

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Plan your visit',
          title: 'Hanoi weather.',
          subtitle: 'Four distinct seasons. Each one changes the city\'s character.',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1565C0)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Live weather forecast coming soon. This page shows seasonal averages for planning purposes.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Monthly overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final month in _months)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E7DF)),
            ),
            child: Row(
              children: [
                SizedBox(width: 90, child: Text(month.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                Icon(month.icon, size: 20, color: muted),
                const SizedBox(width: 10),
                Expanded(child: Text(month.desc, style: const TextStyle(color: muted, fontSize: 13))),
                Text(month.temp, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        const SizedBox(height: 28),
        Text('What to pack', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final tip in _packingTips)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tip.icon, color: accent, size: 22),
                    const SizedBox(width: 10),
                    Text(tip.season, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                for (final item in tip.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: muted),
                        const SizedBox(width: 8),
                        Text(item, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Hanoi has a humid subtropical climate. October–November and March–April are generally considered the most comfortable months for sightseeing.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }
}
