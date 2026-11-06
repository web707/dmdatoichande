import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app.dart' show muted;
import '../core/catalog.dart';
import '../core/store.dart';
import '../core/widgets.dart';

Future<void> showAccountDialog(BuildContext context, GuideStore store) =>
    showDialog<void>(context: context, builder: (_) => _AccountDialog(store));

class _AccountDialog extends StatefulWidget {
  final GuideStore store;
  const _AccountDialog(this.store);
  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.authenticate(
        email.text,
        password.text,
        register: register,
      );
      if (mounted) Navigator.pop(context);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store.user != null) {
      return AlertDialog(
        title: Text(widget.store.isAdmin ? 'Admin account' : 'Your account'),
        content: Text(widget.store.user!['email'].toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await widget.store.logout();
                    } catch (_) {
                      /* Local session is cleared even if server is unavailable. */
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Sign out'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(register ? 'Make yourself at home.' : 'Welcome back.'),
      content: SizedBox(
        width: 390,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  register
                      ? 'Create a traveller account to keep your own phrases in sync.'
                      : 'Sign in to manage your own phrases or the content studio.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value == null ||
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value.trim())
                      ? 'Enter a valid email address'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 10 characters',
                  ),
                  validator: (value) =>
                      value == null || value.length < 10 || value.length > 128
                      ? 'Use 10–128 characters'
                      : null,
                  onFieldSubmitted: (_) {
                    if (!busy) submit();
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 15),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          register = !register;
                          error = null;
                        }),
                  child: Text(
                    register
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy
                ? 'Please wait…'
                : register
                ? 'Create account'
                : 'Sign in',
          ),
        ),
      ],
    );
  }
}

class FieldSpec {
  final String key, label;
  final bool required, multiline, numeric;
  const FieldSpec(
    this.key,
    this.label, {
    this.required = true,
    this.multiline = false,
    this.numeric = false,
  });
}

const recordFields = <String, List<FieldSpec>>{
  'places': [
    FieldSpec('name_vi', 'Vietnamese name'),
    FieldSpec('name_en', 'English name'),
    FieldSpec('summary_en', 'Short introduction', multiline: true),
    FieldSpec('history_en', 'History (English)', multiline: true),
    FieldSpec('culture_en', 'Culture (English)', multiline: true),
    FieldSpec('image_url', 'Image URL (HTTPS)'),
    FieldSpec('image_credit', 'Image author / licence / source'),
    FieldSpec('address', 'Address'),
    FieldSpec('latitude', 'Latitude', numeric: true),
    FieldSpec('longitude', 'Longitude', numeric: true),
    FieldSpec('source_url', 'Content source URL', required: false),
    FieldSpec('opening_hours', 'Opening hours', required: false),
    FieldSpec(
      'ticket_price_vnd',
      'Ticket price (VND)',
      required: false,
      numeric: true,
    ),
    FieldSpec(
      'ticket_price_usd',
      'Ticket price (USD)',
      required: false,
      numeric: true,
    ),
    FieldSpec(
      'booking_info',
      'Tickets & booking info',
      required: false,
      multiline: true,
    ),
    FieldSpec(
      'visit_duration_min',
      'Suggested visit (minutes)',
      required: false,
      numeric: true,
    ),
    FieldSpec(
      'best_time_to_visit',
      'Best time to visit',
      required: false,
      multiline: true,
    ),
  ],
  'phrases': [
    FieldSpec('vietnamese_text', 'Vietnamese phrase'),
    FieldSpec('english_meaning', 'English meaning', multiline: true),
    FieldSpec('pronunciation_guide', 'Approximate pronunciation'),
    FieldSpec('ipa', 'IPA (optional)', required: false),
    FieldSpec(
      'usage_note_en',
      'Usage note (English)',
      required: false,
      multiline: true,
    ),
  ],
  'foods_restaurants': [
    FieldSpec('food_key', 'Dish key (e.g. pho-bo)'),
    FieldSpec('food_name_vi', 'Vietnamese dish name'),
    FieldSpec('food_name_en', 'English dish name'),
    FieldSpec('description_en', 'About the dish (English)', multiline: true),
    FieldSpec('restaurant_name', 'Restaurant name'),
    FieldSpec('address', 'Restaurant address'),
    FieldSpec('latitude', 'Latitude', numeric: true),
    FieldSpec('longitude', 'Longitude', numeric: true),
    FieldSpec('image_url', 'Image URL (HTTPS, optional)', required: false),
    FieldSpec(
      'image_credit',
      'Image credit (required when using an image)',
      required: false,
    ),
    FieldSpec('source_url', 'Content source URL', required: false),
  ],
};
Future<void> showRecordEditor(
  BuildContext context,
  GuideStore store,
  String collection, {
  CatalogRecord? record,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _RecordEditor(store, collection, record),
);

class _RecordEditor extends StatefulWidget {
  final GuideStore store;
  final String collection;
  final CatalogRecord? record;
  const _RecordEditor(this.store, this.collection, this.record);
  @override
  State<_RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<_RecordEditor> {
  final form = GlobalKey<FormState>();
  late final fields = recordFields[widget.collection]!;
  late final controllers = {
    for (final field in fields)
      field.key: TextEditingController(
        text: widget.record?.text(field.key) ?? '',
      ),
  };
  late String category = widget.record?.text('category') ?? 'greetings';
  bool busy = false;
  bool preview = false;
  LatLng? previewPoint;
  String? error;
  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? validate(FieldSpec field, String? value) {
    final input = value?.trim() ?? '';
    if (field.required && input.isEmpty) return 'This field is required';
    if (!field.required && input.isEmpty) return null;
    if (input.length > 6000) return 'Use fewer than 6,000 characters';
    if (field.numeric) {
      if (field.key == 'ticket_price_vnd') {
        final number = int.tryParse(input);
        if (number == null || number < 0 || number > 10000000) {
          return 'Enter an integer between 0 and 10,000,000';
        }
      } else if (field.key == 'ticket_price_usd') {
        final number = double.tryParse(input);
        if (number == null || !number.isFinite || number < 0 || number > 9999) {
          return 'Enter a number between 0 and 9,999';
        }
      } else if (field.key == 'visit_duration_min') {
        final number = int.tryParse(input);
        if (number == null || number < 0 || number > 1440) {
          return 'Enter minutes between 0 and 1,440';
        }
      } else {
        final number = double.tryParse(input);
        final limit = field.key == 'latitude' ? 90 : 180;
        if (number == null || !number.isFinite || number.abs() > limit) {
          return 'Enter a number between -$limit and $limit';
        }
      }
    }
    if (input.isNotEmpty && field.key.endsWith('_url')) {
      final uri = Uri.tryParse(input);
      if (uri == null ||
          !uri.hasAuthority ||
          ![
            'https',
            if (field.key == 'source_url') 'http',
          ].contains(uri.scheme)) {
        return 'Enter a valid ${field.key == 'image_url' ? 'HTTPS' : 'HTTP/HTTPS'} URL';
      }
    }
    if (field.key == 'food_key' &&
        !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(input)) {
      return 'Use lowercase words separated by hyphens';
    }
    if (field.key == 'image_credit' &&
        input.isEmpty &&
        (controllers['image_url']?.text.trim().isNotEmpty ?? false)) {
      return 'Credit is required for this image';
    }
    return null;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final data = <String, dynamic>{
      for (final field in fields)
        field.key: field.numeric
            ? (field.key == 'ticket_price_vnd' ||
                    field.key == 'visit_duration_min'
                ? (int.tryParse(controllers[field.key]!.text.trim()) ?? 0)
                : (double.tryParse(controllers[field.key]!.text.trim()) ?? 0.0))
            : controllers[field.key]!.text.trim(),
    };
    if (widget.collection == 'phrases') data['category'] = category;
    try {
      await widget.store.save(widget.collection, data, id: widget.record?.id);
      if (mounted) Navigator.pop(context);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      '${widget.record == null ? 'Add' : 'Edit'} ${switch (widget.collection) {
        'places' => 'place',
        'phrases' => 'phrase',
        _ => 'restaurant',
      }}',
    ),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.collection == 'phrases')
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    widget.record?.isPrivate == true || !widget.store.isAdmin
                        ? 'This phrase is private to your account.'
                        : 'This phrase will be visible to all travellers.',
                    style: const TextStyle(color: muted),
                  ),
                ),
              if (widget.collection == 'foods_restaurants')
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'Restaurants with the same dish key share the dish name and description. Saving updates those dish details for the whole group.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              for (final field in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: controllers[field.key],
                    decoration: InputDecoration(labelText: field.label),
                    minLines: field.multiline ? 3 : 1,
                    maxLines: field.multiline ? 5 : 1,
                    keyboardType: field.numeric
                        ? const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          )
                        : null,
                    validator: (value) => validate(field, value),
                  ),
                ),
              if (widget.collection == 'phrases')
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final value in [
                      'greetings',
                      'shopping',
                      'food',
                      'directions',
                      'other',
                    ])
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) => setState(() => category = value!),
                ),
              if (controllers.containsKey('image_url'))
                TextButton.icon(
                  onPressed: () => setState(() => preview = !preview),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(preview ? 'Hide image preview' : 'Preview image'),
                ),
              if (preview &&
                  (controllers['image_url']?.text.startsWith('https://') ??
                      false))
                SizedBox(
                  height: 150,
                  child: Image.network(
                    controllers['image_url']!.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text('Could not load this image. Check its URL.'),
                    ),
                  ),
                ),
              if (controllers.containsKey('latitude')) ...[
                TextButton.icon(
                  onPressed: () {
                    final lat = double.tryParse(
                      controllers['latitude']!.text.trim(),
                    );
                    final lon = double.tryParse(
                      controllers['longitude']!.text.trim(),
                    );
                    if (lat == null ||
                        lon == null ||
                        !validCoordinates(lat, lon)) {
                      setState(
                        () => error = 'Enter valid latitude and longitude before previewing.',
                      );
                      return;
                    }
                    setState(() {
                      previewPoint = LatLng(lat, lon);
                      error = null;
                    });
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Preview location'),
                ),
                if (previewPoint != null)
                  SizedBox(
                    height: 240,
                    child: FlutterMap(
                      key: ValueKey(previewPoint),
                      options: MapOptions(
                        initialCenter: previewPoint!,
                        initialZoom: 16,
                        maxZoom: 19,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'vn.hanoiguide.hanoi_travel_guide',
                          maxNativeZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: previewPoint!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.deepOrange,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                        SimpleAttributionWidget(
                          source: const Text(
                            'OpenStreetMap contributors',
                            style: TextStyle(fontSize: 10),
                          ),
                          onTap: () => launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text(
                  'Hanoi is approximately 21° N, 105.85° E. Check that the pin matches the address.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(busy ? 'Saving…' : 'Save changes'),
      ),
    ],
  );
}

Future<void> confirmDelete(
  BuildContext context,
  GuideStore store,
  CatalogRecord record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this item?'),
      content: Text(
        '“${record.title}” will be removed from the guide. This cannot be undone in the app.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep it'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await store.delete(record);
  } catch (error) {
    if (context.mounted) showMessage(context, error.toString());
  }
}
