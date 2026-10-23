import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/building_maintenance.dart';
import '../models/room.dart';
import '../models/staff.dart';
import '../repositories/building_maintenance_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/staff_repository.dart';
import 'settings_page.dart';

/// Dashboard: at-a-glance summary of rooms, maintenance, and staff.
/// Each card navigates to its tab.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.roomRepository,
    required this.maintenanceRepository,
    required this.staffRepository,
    required this.onOpenRooms,
    required this.onOpenMaintenance,
    required this.onOpenStaff,
  });

  final RoomRepository roomRepository;
  final BuildingMaintenanceRepository maintenanceRepository;
  final StaffRepository staffRepository;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenMaintenance;
  final VoidCallback onOpenStaff;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConfig.appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('Rooms'),
          StreamBuilder<List<Room>>(
            stream: roomRepository.watchRooms(),
            builder: (context, snapshot) {
              final rooms = snapshot.data ?? const <Room>[];
              final occupied =
                  rooms.where((r) => r.tenantName?.isNotEmpty ?? false).length;
              final dueSoon =
                  rooms.where((r) {
                    final due = r.payment.nextDueDate;
                    if (due == null) return false;
                    return due.difference(DateTime.now()).inDays <=
                        AppConfig.paymentDueSoonDays;
                  }).length;
              return _SummaryCard(
                icon: Icons.meeting_room,
                title: 'Occupancy',
                value: '$occupied / ${AppConfig.totalRooms}',
                subtitle:
                    '$dueSoon payment(s) due within ${AppConfig.paymentDueSoonDays} days',
                onTap: onOpenRooms,
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionLabel('Building Maintenance'),
          StreamBuilder<BuildingMaintenance?>(
            stream: maintenanceRepository.watchGlobalStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data;
              return _SummaryCard(
                icon: Icons.handyman,
                title: 'Global Stats',
                value: stats == null ? 'No data yet' : 'Up to date',
                subtitle:
                    stats == null
                        ? 'Tap to log water, septic & electricity'
                        : 'Water: ${_formatDate(stats.waterLastCleaned)}  •  '
                            'Septic: ${_formatDate(stats.septicLastCleaned)}',
                onTap: onOpenMaintenance,
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionLabel('Staff'),
          StreamBuilder<List<Staff>>(
            stream: staffRepository.watchStaff(),
            builder: (context, snapshot) {
              final staff = snapshot.data ?? const <Staff>[];
              final active = staff.where((s) => s.isActive).length;
              return _SummaryCard(
                icon: Icons.people,
                title: 'Staff on Duty',
                value: '$active active',
                subtitle: '${staff.length} total on record',
                onTap: onOpenStaff,
              );
            },
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.onSurfaceMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
