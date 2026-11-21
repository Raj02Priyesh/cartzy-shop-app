import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../state/auth_provider.dart';

/// Adds a delivery address. Pops with the saved [Address].
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _locality = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();
  final _country = TextEditingController(text: 'India');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_street, _locality, _area, _city, _district, _state, _pin, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await context.read<AuthProvider>().addAddress(Address(
            street: _street.text.trim(),
            locality: _locality.text.trim(),
            area: _area.text.trim(),
            city: _city.text.trim(),
            district: _district.text.trim(),
            state: _state.text.trim(),
            pinCode: _pin.text.trim(),
            country: _country.text.trim(),
          ));
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _saving = false);
      }
    }
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, TextInputType? keyboard, String? Function(String?)? validator, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add address')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_street, 'House no., building, street', hint: 'e.g. 12B, Green Park Society, Baner Road'),
            _field(_locality, 'Locality / post office', hint: 'e.g. Baner'),
            _field(_area, 'Area / taluk', hint: 'e.g. Pune City'),
            Row(
              children: [
                Expanded(child: _field(_city, 'City')),
                const SizedBox(width: 12),
                Expanded(child: _field(_district, 'District')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_state, 'State')),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _pin,
                    'PIN code',
                    keyboard: TextInputType.number,
                    maxLength: 6,
                    validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : 'Enter a 6-digit PIN',
                  ),
                ),
              ],
            ),
            _field(_country, 'Country'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Save address'),
            ),
          ],
        ),
      ),
    );
  }
}
