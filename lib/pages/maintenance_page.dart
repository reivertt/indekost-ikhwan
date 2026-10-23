import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/maintenance_log.dart';
import '../models/room.dart';
import '../repositories/maintenance_log_repository.dart';
import '../repositories/room_repository.dart';

/// Maintenance tab: chronological list of maintenance logs with a
/// FAB to add new room or building entries.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({
    super.key,
    required this.repository,
    required this.roomRepository,
  });

  final MaintenanceLogRepository repository;
  final RoomRepository roomRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maintenance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<MaintenanceLog>>(
        stream: repository.watchLogs(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.handyman_outlined,
                    size: 48,
                    color: AppColors.onSurfaceMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No maintenance logs yet.\nTap + to add the first one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Dismissible(
                key: ValueKey(log.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => repository.deleteLog(log.id),
                child: _LogTile(
                  log: log,
                  onTap:
                      () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder:
                            (_) => _AddLogSheet(
                              repository: repository,
                              roomRepository: roomRepository,
                              existing: log,
                            ),
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add maintenance log',
        onPressed:
            () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder:
                  (_) => _AddLogSheet(
                    repository: repository,
                    roomRepository: roomRepository,
                  ),
            ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.onTap});

  final MaintenanceLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scopeLabel =
        log.scope == MaintenanceScope.room
            ? 'Room ${log.roomId ?? '?'}'
            : 'Building';
    final hasNotes = log.notes?.isNotEmpty ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Icon(categoryIcon(log.category), size: 20),
        ),
        title: Text(categoryLabel(log.category)),
        subtitle: Text(hasNotes ? '$scopeLabel\n${log.notes}' : scopeLabel),
        isThreeLine: hasNotes,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(log.date),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
            ),
            if (log.amount != null)
              Text(
                'Rp ${log.amount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddLogSheet extends StatefulWidget {
  const _AddLogSheet({
    required this.repository,
    required this.roomRepository,
    this.existing,
  });

  final MaintenanceLogRepository repository;
  final RoomRepository roomRepository;
  final MaintenanceLog? existing;

  @override
  State<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<_AddLogSheet> {
  late MaintenanceScope? _scope = widget.existing?.scope;
  late MaintenanceCategory _category =
      widget.existing?.category ?? MaintenanceCategory.other;
  late String? _roomId = widget.existing?.roomId;
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  bool _saving = false;

  late final _notesController = TextEditingController(
    text: widget.existing?.notes,
  );
  late final _amountController = TextEditingController(
    text: widget.existing?.amount?.toString() ?? '',
  );

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
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
        child: _scope == null ? _buildScopeChooser() : _buildForm(),
      ),
    );
  }

  Widget _buildScopeChooser() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add maintenance log',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ScopeOption(
                icon: Icons.meeting_room_outlined,
                label: 'Room',
                onTap:
                    () => setState(() {
                      _scope = MaintenanceScope.room;
                      _category = MaintenanceCategory.bathroom;
                    }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScopeOption(
                icon: Icons.apartment_outlined,
                label: 'Building',
                onTap:
                    () => setState(() {
                      _scope = MaintenanceScope.building;
                      _category = MaintenanceCategory.water;
                    }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    final scope = _scope!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (widget.existing == null)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Change scope',
                onPressed: () => setState(() => _scope = null),
              ),
            Expanded(
              child: Text(
                widget.existing != null
                    ? 'Edit maintenance log'
                    : scope == MaintenanceScope.room
                    ? 'Room maintenance'
                    : 'Building maintenance',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (scope == MaintenanceScope.room) ...[
          FutureBuilder<List<Room>>(
            future: widget.roomRepository.getRooms(),
            builder: (context, snapshot) {
              final rooms = snapshot.data ?? const <Room>[];
              return DropdownButtonFormField<String>(
                initialValue: _roomId,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final room in rooms)
                    DropdownMenuItem(value: room.id, child: Text(room.id)),
                ],
                onChanged: (value) => setState(() => _roomId = value),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<MaintenanceCategory>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final category in categoriesForScope(scope))
              DropdownMenuItem(
                value: category,
                child: Text(categoryLabel(category)),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _category = value);
          },
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(),
            ),
            child: Row(
              children: [
                Expanded(child: Text(_formatDate(_date))),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
        if (_category == MaintenanceCategory.electricity) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Token amount (Rp)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.check),
          label: Text(widget.existing == null ? 'Save log' : 'Save changes'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_scope == MaintenanceScope.room && _roomId == null) {
      _showError('Please select a room.');
      return;
    }
    int? amount;
    if (_category == MaintenanceCategory.electricity &&
        _amountController.text.trim().isNotEmpty) {
      amount = int.tryParse(_amountController.text.trim());
      if (amount == null) {
        _showError('Token amount must be a number.');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final log = MaintenanceLog(
        id: widget.existing?.id ?? '',
        scope: _scope!,
        category: _category,
        date: _date,
        roomId: _scope == MaintenanceScope.room ? _roomId : null,
        notes: _notesController.text.trim(),
        amount: amount,
      );
      if (widget.existing == null) {
        await widget.repository.addLog(log);
      } else {
        await widget.repository.updateLog(widget.existing!.id, log);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

String categoryLabel(MaintenanceCategory category) => switch (category) {
  MaintenanceCategory.water => 'Water cleaning',
  MaintenanceCategory.septic => 'Septic cleaning',
  MaintenanceCategory.electricity => 'Electricity token',
  MaintenanceCategory.bathroom => 'Bathroom cleaning',
  MaintenanceCategory.airCon => 'AC cleaning',
  MaintenanceCategory.lightBulbMain => 'Light bulb (main room)',
  MaintenanceCategory.lightBulbBath => 'Light bulb (bathroom)',
  MaintenanceCategory.paintWalls => 'Repaint walls',
  MaintenanceCategory.toiletFaucet => 'Toilet faucet replacement',
  MaintenanceCategory.showerHead => 'Shower head replacement',
  MaintenanceCategory.washCurtain => 'Room curtain cleaning',
  MaintenanceCategory.washBed => 'Bed wash',
  MaintenanceCategory.other => 'Other',
};

IconData categoryIcon(MaintenanceCategory category) => switch (category) {
  MaintenanceCategory.water => Icons.water_drop_outlined,
  MaintenanceCategory.septic => Icons.plumbing_outlined,
  MaintenanceCategory.electricity => Icons.electric_bolt_outlined,
  MaintenanceCategory.bathroom => Icons.bathroom_outlined,
  MaintenanceCategory.airCon => Icons.ac_unit_outlined,
  MaintenanceCategory.paintWalls => Icons.format_paint,
  MaintenanceCategory.toiletFaucet => Icons.wc_outlined,
  MaintenanceCategory.showerHead => Icons.shower_outlined,
  MaintenanceCategory.washCurtain => Icons.curtains_outlined,
  MaintenanceCategory.washBed => Icons.bed_outlined,
  MaintenanceCategory.lightBulbMain ||
  MaintenanceCategory.lightBulbBath => Icons.lightbulb_outline,
  MaintenanceCategory.other => Icons.build_outlined,
};
