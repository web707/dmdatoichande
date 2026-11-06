import 'package:flutter/material.dart';
import '../app/app.dart' show muted;
import '../core/widgets.dart';

// Reference rates — updated manually. For informational use only.
const _rates = {
  'USD': 25450.0,
  'EUR': 27300.0,
  'GBP': 32200.0,
  'JPY': 168.0,
  'KRW': 18.5,
  'AUD': 16800.0,
};

const _rateDate = 'November 2026';

const _denominations = [500000, 200000, 100000, 50000, 20000, 10000, 5000, 2000, 1000, 500, 200, 100];

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});
  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _vndController = TextEditingController();
  String _fromCurrency = 'USD';
  final _foreignController = TextEditingController();
  bool _vndToForeign = true;

  int get _vndAmount => int.tryParse(_vndController.text.replaceAll(',', '')) ?? 0;
  double get _foreignAmount => double.tryParse(_foreignController.text) ?? 0;

  Map<String, int> _breakdown(int vnd) {
    final result = <String, int>{};
    var remaining = vnd;
    for (final d in _denominations) {
      if (remaining >= d) {
        result[d.toString()] = remaining ~/ d;
        remaining = remaining % d;
      }
    }
    return result;
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

  @override
  void dispose() {
    _vndController.dispose();
    _foreignController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rates[_fromCurrency] ?? 25450.0;
    final convertedForeign = _vndToForeign ? (_vndAmount / rate) : 0.0;
    final convertedVnd = _vndToForeign ? 0 : (_foreignAmount * rate).round();
    final breakdown = _breakdown(_vndToForeign ? _vndAmount : convertedVnd);

    return PageBody(
      children: [
        const SectionHeading(
          eyebrow: 'Money in Vietnam',
          title: 'Currency converter.',
          subtitle: 'Convert between Vietnamese Đồng and major currencies. For reference only.',
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
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('VND → Foreign'),
                      selected: _vndToForeign,
                      onSelected: (_) => setState(() { _vndToForeign = true; _vndController.clear(); }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Foreign → VND'),
                      selected: !_vndToForeign,
                      onSelected: (_) => setState(() { _vndToForeign = false; _foreignController.clear(); }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _fromCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: _rates.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => _fromCurrency = v!),
              ),
              const SizedBox(height: 14),
              if (_vndToForeign)
                TextField(
                  controller: _vndController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (VND)', suffixText: 'VND'),
                  onChanged: (_) => setState(() {}),
                )
              else
                TextField(
                  controller: _foreignController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Amount ($_fromCurrency)', suffixText: _fromCurrency),
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 20),
              if (_vndToForeign && _vndAmount > 0)
                _ResultBox(
                  label: _fromCurrency,
                  value: convertedForeign.toStringAsFixed(2),
                  note: '1 $_fromCurrency ≈ ${_formatVnd(rate.round())} VND',
                )
              else if (!_vndToForeign && _foreignAmount > 0)
                _ResultBox(
                  label: 'VND',
                  value: _formatVnd(convertedVnd),
                  note: '1 $_fromCurrency ≈ ${_formatVnd(rate.round())} VND',
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Reference rate as of $_rateDate. Always check current rates before transactions.',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 28),
        // Denomination breakdown
        if (breakdown.isNotEmpty) ...[
          Text('Banknote breakdown', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'How many of each note to make up ${_formatVnd(_vndToForeign ? _vndAmount : convertedVnd)} VND:',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in breakdown.entries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE1E7DF)),
                  ),
                  child: Column(
                    children: [
                      Text(_formatVnd(int.parse(entry.key)),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('× ${entry.value}', style: const TextStyle(color: muted)),
                    ],
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        Text('Common denominations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final d in [500000, 200000, 100000, 50000, 20000, 10000])
              _DenomChip(d, _formatVnd(d), (d / rate).toStringAsFixed(2), _fromCurrency),
          ],
        ),
      ],
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String label, value, note;
  const _ResultBox({required this.label, required this.value, required this.note});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('≈', style: const TextStyle(fontSize: 22, color: Color(0xFF388E3C))),
        Text('$value $label', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
        const SizedBox(height: 4),
        Text(note, style: const TextStyle(fontSize: 12, color: Color(0xFF388E3C))),
      ],
    ),
  );
}

class _DenomChip extends StatelessWidget {
  final int vnd;
  final String vndFmt, foreignFmt, currency;
  const _DenomChip(this.vnd, this.vndFmt, this.foreignFmt, this.currency);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E7DF)),
    ),
    child: Column(
      children: [
        Text('$vndFmt đ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Text('≈ $foreignFmt $currency', style: const TextStyle(fontSize: 11, color: muted)),
      ],
    ),
  );
}
