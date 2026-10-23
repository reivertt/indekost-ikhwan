import 'package:flutter/material.dart';

import '../models/room.dart';
import '../repositories/room_repository.dart';

/// Bottom-sheet form to edit a room's tenant, contact, and payment info.
class RoomFormSheet extends StatefulWidget {
  const RoomFormSheet({
    super.key,
    required this.repository,
    required this.room,
  });

  final RoomRepository repository;
  final Room room;

  @override
  State<RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<RoomFormSheet> {
  late final _typeController = TextEditingController(text: widget.room.type);
  late final _priceController = TextEditingController(
    text: '${widget.room.pricePer6Months}',
  );
  late final _tenantController = TextEditingController(
    text: widget.room.tenantName,
  );
  late final _phoneController = TextEditingController(
    text: widget.room.phoneNumber,
  );
  late final _guardianController = TextEditingController(
    text: widget.room.guardianContact,
  );
  late final _vehicleController = TextEditingController(
    text: widget.room.vehiclePlate,
  );
  late final _amountPaidController = TextEditingController(
    text: widget.room.payment.amountPaid?.toString() ?? '',
  );
  late DateTime? _nextDueDate = widget.room.payment.nextDueDate;
  bool _saving = false;

  @override
  void dispose() {
    _typeController.dispose();
    _priceController.dispose();
    _tenantController.dispose();
    _phoneController.dispose();
    _guardianController.dispose();
    _vehicleController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit room ${widget.room.id}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Type',
                hintText: 'e.g. AC, Fan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price per 6 months (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tenantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tenant name (leave empty if unoccupied)',
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
              controller: _guardianController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Guardian contact (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vehicleController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Vehicle plate (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Last amount paid (Rp, optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickNextDueDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Next payment due',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _nextDueDate == null ? '—' : _formatDate(_nextDueDate!),
                      ),
                    ),
                    if (_nextDueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _nextDueDate = null),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.clear, size: 18),
                        ),
                      ),
                    const Icon(Icons.calendar_today_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickNextDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  Future<void> _save() async {
    final type = _typeController.text.trim();
    if (type.isEmpty) {
      _showError('Type is required.');
      return;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      _showError('Price must be a number.');
      return;
    }
    int? amountPaid;
    if (_amountPaidController.text.trim().isNotEmpty) {
      amountPaid = int.tryParse(_amountPaidController.text.trim());
      if (amountPaid == null) {
        _showError('Amount paid must be a number.');
        return;
      }
    }
    final updated = Room(
      id: widget.room.id,
      type: type,
      pricePer6Months: price,
      tenantName: _emptyToNull(_tenantController.text),
      phoneNumber: _emptyToNull(_phoneController.text),
      guardianContact: _emptyToNull(_guardianController.text),
      vehiclePlate: _emptyToNull(_vehicleController.text),
      checkInDate: widget.room.checkInDate,
      maintenance: widget.room.maintenance,
      payment: RoomPayment(
        lastPaidDate: widget.room.payment.lastPaidDate,
        amountPaid: amountPaid,
        nextDueDate: _nextDueDate,
      ),
    );
    setState(() => _saving = true);
    try {
      await widget.repository.updateRoom(widget.room.id, updated);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Failed to save: $e');
    }
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
