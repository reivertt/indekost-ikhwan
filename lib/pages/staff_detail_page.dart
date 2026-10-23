import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/staff.dart';
import '../repositories/staff_repository.dart';
import 'staff_form_sheet.dart';

/// Staff detail: member info, edit/delete actions, and their work logs.
class StaffDetailPage extends StatelessWidget {
  const StaffDetailPage({
    super.key,
    required this.repository,
    required this.staffId,
  });

  final StaffRepository repository;
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Staff>>(
      stream: repository.watchStaff(),
      builder: (context, snapshot) {
        final member = snapshot.data
            ?.where((s) => s.id == staffId)
            .firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              member?.name ?? 'Staff',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (member != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit staff',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => StaffFormSheet(
                      repository: repository,
                      existing: member,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete staff',
                  onPressed: () => _confirmDelete(context, member),
                ),
              ],
            ],
          ),
          body: _buildBody(context, snapshot, member),
          floatingActionButton: member == null
              ? null
              : FloatingActionButton(
                  tooltip: 'Add work log',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) =>
                        _WorkLogFormSheet(repository: repository, staffId: staffId),
                  ),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Staff>> snapshot,
    Staff? member,
  ) {
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (member == null) {
      return const Center(child: Text('Staff member not found.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: member.role,
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: member.phoneNumber ?? '—',
                ),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Pay rate',
                  value: '${formatRupiah(member.payRatePerMonth)}/month',
                ),
                _InfoRow(
                  icon: member.isActive
                      ? Icons.check_circle_outline
                      : Icons.circle_outlined,
                  label: 'Status',
                  value: member.isActive ? 'Active' : 'Inactive',
                  valueColor: member.isActive
                      ? AppColors.success
                      : AppColors.onSurfaceMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Work Logs',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        StreamBuilder<List<WorkLog>>(
          stream: repository.watchWorkLogs(staffId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final logs = snapshot.data!;
            if (logs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No work logs yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ),
              );
            }
            final totalPay =
                logs.fold<int>(0, (sum, log) => sum + log.totalPay);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    '${logs.length} entr${logs.length == 1 ? 'y' : 'ies'}  •  ${formatRupiah(totalPay)} total',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ),
                for (final log in logs) _WorkLogTile(log: log),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Staff member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete staff member?'),
        content: Text(
            'This will remove ${member.name} and all their work logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await repository.deleteStaff(member.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _WorkLogTile extends StatelessWidget {
  const _WorkLogTile({required this.log});

  final WorkLog log;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.work_history_outlined, size: 20),
        ),
        title: Text(
          log.tasksCompleted.isEmpty ? 'Work log' : log.tasksCompleted,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
            '${log.date.day}/${log.date.month}/${log.date.year}  •  ${log.hoursWorked}h'),
        trailing: Text(
          formatRupiah(log.totalPay),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _WorkLogFormSheet extends StatefulWidget {
  const _WorkLogFormSheet({required this.repository, required this.staffId});

  final StaffRepository repository;
  final String staffId;

  @override
  State<_WorkLogFormSheet> createState() => _WorkLogFormSheetState();
}

class _WorkLogFormSheetState extends State<_WorkLogFormSheet> {
  DateTime _date = DateTime.now();
  bool _saving = false;

  final _hoursController = TextEditingController();
  final _tasksController = TextEditingController();
  final _payController = TextEditingController();

  @override
  void dispose() {
    _hoursController.dispose();
    _tasksController.dispose();
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
              'Add work log',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                    Expanded(
                      child: Text(
                          '${_date.day}/${_date.month}/${_date.year}'),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hours worked',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tasksController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tasks completed',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _payController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total pay (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Save log'),
            ),
          ],
        ),
      ),
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
    final hours = int.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) {
      _showError('Hours worked must be a positive number.');
      return;
    }
    final pay = int.tryParse(_payController.text.trim());
    if (pay == null || pay < 0) {
      _showError('Total pay must be a number.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.addWorkLog(
        widget.staffId,
        WorkLog(
          id: '',
          date: _date,
          hoursWorked: hours,
          tasksCompleted: _tasksController.text.trim(),
          totalPay: pay,
        ),
      );
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
