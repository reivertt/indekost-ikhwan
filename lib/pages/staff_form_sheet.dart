import 'package:flutter/material.dart';

import '../models/staff.dart';
import '../repositories/staff_repository.dart';

/// Bottom-sheet form to add or edit a staff member.
class StaffFormSheet extends StatefulWidget {
  const StaffFormSheet({
    super.key,
    required this.repository,
    this.existing,
  });

  final StaffRepository repository;
  final Staff? existing;

  @override
  State<StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<StaffFormSheet> {
  late final _nameController =
      TextEditingController(text: widget.existing?.name);
  late final _roleController =
      TextEditingController(text: widget.existing?.role);
  late final _phoneController =
      TextEditingController(text: widget.existing?.phoneNumber);
  late final _payController = TextEditingController(
    text: widget.existing != null
        ? '${widget.existing!.payRatePerMonth}'
        : '',
  );
  late bool _isActive = widget.existing?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _payController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add staff' : 'Edit staff',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Role',
                hintText: 'e.g. Cleaner, Security',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _payController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pay rate per month (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(widget.existing == null ? 'Add staff' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    if (name.isEmpty || role.isEmpty) {
      _showError('Name and role are required.');
      return;
    }
    final pay = int.tryParse(_payController.text.trim()) ?? 0;
    final staff = Staff(
      id: widget.existing?.id ?? '',
      name: name,
      role: role,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      payRatePerMonth: pay,
      isActive: _isActive,
    );
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.repository.addStaff(staff);
      } else {
        await widget.repository.updateStaff(staff.id, staff);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Failed to save: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

String formatRupiah(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer('Rp ');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
