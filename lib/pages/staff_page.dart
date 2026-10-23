import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/staff.dart';
import '../repositories/staff_repository.dart';
import 'staff_detail_page.dart';
import 'staff_form_sheet.dart';

/// Staff tab: manage staff members — add, edit, delete, and open
/// a member's detail page for work logs.
class StaffPage extends StatelessWidget {
  const StaffPage({super.key, required this.repository});

  final StaffRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Staff>>(
        stream: repository.watchStaff(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final staff = snapshot.data!
            ..sort((a, b) => a.name.compareTo(b.name));
          if (staff.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline,
                      size: 48, color: AppColors.onSurfaceMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No staff yet.\nTap + to add the first one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final member = staff[index];
              return Dismissible(
                key: ValueKey(member.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context, member),
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
                onDismissed: (_) => repository.deleteStaff(member.id),
                child: _StaffTile(
                  member: member,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StaffDetailPage(
                        repository: repository,
                        staffId: member.id,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add staff',
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => StaffFormSheet(repository: repository),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Staff member) async {
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
    return confirmed ?? false;
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.onTap});

  final Staff member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: member.isActive
              ? AppColors.primaryLight
              : AppColors.onSurfaceMuted.withValues(alpha: 0.15),
          foregroundColor: member.isActive
              ? AppColors.primary
              : AppColors.onSurfaceMuted,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          ),
        ),
        title: Text(
          member.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: member.isActive ? null : AppColors.onSurfaceMuted,
          ),
        ),
        subtitle: Text(
          '${member.role}  •  ${formatRupiah(member.payRatePerMonth)}/month',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              member.isActive ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: member.isActive
                  ? AppColors.success
                  : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}
