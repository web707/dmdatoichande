import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/app.dart' show muted;
import '../core/widgets.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Everything else',
          title: 'More tools.',
          subtitle: 'Utilities and resources to help you explore Hanoi with confidence.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 2;
            final w = (constraints.maxWidth - 14 * (cols - 1)) / cols;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(width: w, child: _ToolCard(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved phrases',
                  subtitle: 'Your bookmarked phrases',
                  color: const Color(0xFF173E35),
                  onTap: () => context.go('/saved'),
                )),
                SizedBox(width: w, child: _ToolCard(
                  icon: Icons.emergency_outlined,
                  title: 'Emergency',
                  subtitle: 'Police, hospitals, embassies',
                  color: const Color(0xFFB22222),
                  onTap: () => context.go('/emergency'),
                )),
                SizedBox(width: w, child: _ToolCard(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Currency',
                  subtitle: 'VND converter & denominations',
                  color: const Color(0xFF1565C0),
                  onTap: () => context.go('/tools/converter'),
                )),
                SizedBox(width: w, child: _ToolCard(
                  icon: Icons.wb_cloudy_outlined,
                  title: 'Weather',
                  subtitle: 'Seasonal guide for Hanoi',
                  color: const Color(0xFF00838F),
                  onTap: () => context.go('/tools/weather'),
                )),
                SizedBox(width: w, child: _ToolCard(
                  icon: Icons.map_outlined,
                  title: 'Itinerary',
                  subtitle: 'Plan your days in Hanoi',
                  color: const Color(0xFFC9714B),
                  onTap: () => context.go('/tools/itinerary'),
                )),
                SizedBox(width: w, child: _ToolCard(
                  icon: Icons.view_in_ar_outlined,
                  title: 'VR360',
                  subtitle: 'Interactive heritage tour',
                  color: const Color(0xFF4A148C),
                  onTap: () => context.go('/tools/vr360'),
                )),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ToolCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE1E7DF)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
    ),
  );
}
