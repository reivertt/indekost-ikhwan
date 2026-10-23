import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/maintenance_log.dart';
import '../models/room.dart';
import '../repositories/maintenance_log_repository.dart';
import '../repositories/room_repository.dart';
import 'maintenance_page.dart' show categoryIcon, categoryLabel;
import 'room_form_sheet.dart';
import 'staff_form_sheet.dart' show formatRupiah;

/// Room detail: tenant & room info, mandatory maintenance status
/// (payment, bathroom, lights, aircon), and recent maintenance logs.
class RoomDetailPage extends StatelessWidget {
  const RoomDetailPage({
    super.key,
    required this.roomRepository,
    required this.maintenanceLogRepository,
    required this.roomId,
  });

  final RoomRepository roomRepository;
  final MaintenanceLogRepository maintenanceLogRepository;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: roomRepository.watchRooms(),
      builder: (context, snapshot) {
        final room = snapshot.data?.where((r) => r.id == roomId).firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              room == null ? 'Room' : 'Room ${room.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (room != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit room',
                  onPressed:
                      () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder:
                            (_) => RoomFormSheet(
                              repository: roomRepository,
                              room: room,
                            ),
                      ),
                ),
            ],
          ),
          body: _buildBody(context, snapshot, room),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Room>> snapshot,
    Room? room,
  ) {
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (room == null) {
      return const Center(child: Text('Room not found.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RoomInfoCard(room: room),
        const SizedBox(height: 16),
        const _SectionLabel('Status'),
        _StatusCard(room: room),
        const SizedBox(height: 16),
        const _SectionLabel('Recent maintenance'),
        _RoomLogList(repository: maintenanceLogRepository, roomId: roomId),
      ],
    );
  }
}

class _RoomInfoCard extends StatelessWidget {
  const _RoomInfoCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final occupied = room.tenantName?.isNotEmpty ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              icon: occupied ? Icons.person : Icons.person_outline,
              label: 'Tenant',
              value: occupied ? room.tenantName! : 'Unoccupied',
              valueColor: occupied ? null : AppColors.onSurfaceMuted,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: room.phoneNumber ?? '—',
            ),
            _InfoRow(
              icon: Icons.contact_phone_outlined,
              label: 'Guardian',
              value: room.guardianContact ?? '—',
            ),
            _InfoRow(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle',
              value: room.vehiclePlate ?? '—',
            ),
            _InfoRow(
              icon: Icons.meeting_room_outlined,
              label: 'Type',
              value: room.type,
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Price',
              value: '${formatRupiah(room.pricePer6Months)} / 6 months',
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Check-in',
              value: _formatDate(room.checkInDate),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff = now.subtract(
      Duration(days: AppConfig.maintenanceDueDays), //! TODO: change this for each
    );
    bool isDue(DateTime? date) => date == null || date.isBefore(cutoff);

    final occupied = room.tenantName?.isNotEmpty ?? false;
    final m = room.maintenance;

    final nextDue = room.payment.nextDueDate;
    final String paymentValue;
    final String paymentStatus;
    final Color paymentColor;
    if (!occupied) {
      paymentValue = '—';
      paymentStatus = 'No tenant';
      paymentColor = AppColors.onSurfaceMuted;
    } else if (nextDue == null) {
      paymentValue = '—';
      paymentStatus = 'No due date';
      paymentColor = AppColors.onSurfaceMuted;
    } else {
      final days = nextDue.difference(now).inDays;
      paymentValue = 'Due ${_formatDate(nextDue)}';
      if (days < 0) {
        paymentStatus = 'Overdue';
        paymentColor = AppColors.danger;
      } else if (days <= AppConfig.paymentDueSoonDays) {
        paymentStatus = 'Due in ${days}d';
        paymentColor = AppColors.warning;
      } else {
        paymentStatus = 'On track';
        paymentColor = AppColors.success;
      }
    }

    final bathroomDue = isDue(m.lastBathroomClean);
    final airConDue = isDue(m.lastAirConClean);
    final roomDue = isDue(m.lastPaintWalls) || isDue(m.lastWashBed) || isDue(m.lastWashCurtain);
    final lightsDue = isDue(m.lastLightBulbMain) || isDue(m.lastLightBulbBath);
    final faucetsDue = isDue(m.lastReplaceShowerHead) || isDue(m.lastReplaceToiletFaucet);


    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _StatusRow(
              icon: Icons.payments_outlined,
              label: 'Payment',
              value: paymentValue,
              status: paymentStatus,
              color: paymentColor,
            ),
            _StatusRow(
              icon: Icons.bathroom_outlined,
              label: 'Bathroom cleaning',
              value: 'Last: ${_formatDate(m.lastBathroomClean)}',
              status: bathroomDue ? 'Due' : 'OK',
              color: bathroomDue ? AppColors.warning : AppColors.success,
            ),
            _StatusRow(
              icon: Icons.ac_unit_outlined,
              label: 'Air conditioning',
              value: 'Last: ${_formatDate(m.lastAirConClean)}',
              status: airConDue ? 'Due' : 'OK',
              color: airConDue ? AppColors.warning : AppColors.success,
            ),
            _StatusRow(
              icon: Icons.lightbulb_outline,
              label: 'Lights',
              value:
                  'Main: ${_formatDate(m.lastLightBulbMain)}  •  '
                  'Bath: ${_formatDate(m.lastLightBulbBath)}',
              status: lightsDue ? 'Due' : 'OK',
              color: lightsDue ? AppColors.warning : AppColors.success,
            ),
            _StatusRow(
              icon: Icons.wc_outlined,
              label: 'Bathroom Faucets',
              value:
                  'Toilet: ${_formatDate(m.lastReplaceToiletFaucet)}  •  '
                  'Shower Head: ${_formatDate(m.lastReplaceShowerHead)}',
              status: faucetsDue ? 'Due' : 'OK',
              color: faucetsDue ? AppColors.warning : AppColors.success,
            ),
            _StatusRow(
              icon: Icons.room_preferences_outlined,
              label: 'Room Maintenance',
              value:
                  'Walls Painted: ${_formatDate(m.lastPaintWalls)}  •  '
                  'Bed Washed: ${_formatDate(m.lastWashBed)}  •  '
                  'Curtains Washed: ${_formatDate(m.lastWashCurtain)}',
              status: roomDue ? 'Due' : 'OK',
              color: roomDue ? AppColors.warning : AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomLogList extends StatelessWidget {
  const _RoomLogList({required this.repository, required this.roomId});

  final MaintenanceLogRepository repository;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MaintenanceLog>>(
      stream: repository.watchRoomLogs(roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data!.take(10).toList();
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No maintenance logs yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ),
          );
        }
        return Column(
          children: [for (final log in logs) _RoomLogTile(log: log)],
        );
      },
    );
  }
}

class _RoomLogTile extends StatelessWidget {
  const _RoomLogTile({required this.log});

  final MaintenanceLog log;

  @override
  Widget build(BuildContext context) {
    final hasNotes = log.notes?.isNotEmpty ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Icon(categoryIcon(log.category), size: 20),
        ),
        title: Text(categoryLabel(log.category)),
        subtitle: hasNotes ? Text(log.notes!) : null,
        trailing: Text(
          _formatDate(log.date),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
        ),
      ),
    );
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
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

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day}/${date.month}/${date.year}';
}
