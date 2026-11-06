import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app.dart' show ink, muted, paper;
import 'catalog.dart';

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1260),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final Widget? action;
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
            color: muted,
          ),
        ),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: muted)),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  const EmptyState(this.title, this.message, {super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Icon(Icons.travel_explore, size: 44, color: muted),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    ),
  );
}

class SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchBox({super.key, required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded, size: 21),
    ),
  );
}

class PlaceImage extends StatelessWidget {
  final CatalogRecord record;
  final double height;
  const PlaceImage(this.record, {super.key, this.height = 210});
  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      final asset = switch (record.id) {
        '10000000-0000-4000-8000-000000000001' => 'assets/images/hoan_kiem.jpg',
        '10000000-0000-4000-8000-000000000002' => 'assets/images/temple.jpg',
        _ => null,
      };
      return asset != null
          ? Image.asset(
              asset,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Container(
              height: height,
              color: paper,
              child: const Center(
                child: Icon(Icons.landscape_outlined, size: 50, color: muted),
              ),
            );
    }

    final bundledUrl = switch (record.id) {
      '10000000-0000-4000-8000-000000000001' =>
        'https://upload.wikimedia.org/wikipedia/commons/7/79/Thap_Rua.jpg',
      '10000000-0000-4000-8000-000000000002' => 'https://upload.wikimedia.org/wikipedia/commons/3/39/Hanoi_Temple_of_Literature_%28cropped%29.jpg',
      _ => null,
    };
    if (record.text('image_url').isEmpty ||
        record.text('image_url') == bundledUrl) {
      return fallback();
    }
    return Image.network(
      record.text('image_url'),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback(),
    );
  }
}

class SourceLink extends StatelessWidget {
  final String url;
  final String label;
  const SourceLink(this.url, {super.key, this.label = 'Read the source'});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () async {
      final uri = Uri.tryParse(url);
      if (uri == null || !['http', 'https'].contains(uri.scheme)) return;
      if (!await launchUrl(uri) && context.mounted) {
        showMessage(context, 'Could not open this link.');
      }
    },
    icon: const Icon(Icons.open_in_new, size: 15),
    label: Text(label, style: const TextStyle(fontSize: 12, color: ink)),
  );
}
