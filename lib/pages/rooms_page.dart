import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/room.dart';
import '../repositories/maintenance_log_repository.dart';
import '../repositories/room_repository.dart';
import 'room_detail_page.dart';

enum _RoomView { map, list }

/// Rooms tab: corridor map (default) or list of all rooms with occupancy,
/// contact, vehicle, and pending-action info.
class RoomsPage extends StatefulWidget {
  const RoomsPage({
    super.key,
    required this.repository,
    required this.maintenanceLogRepository,
  });

  final RoomRepository repository;
  final MaintenanceLogRepository maintenanceLogRepository;

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  _RoomView _view = _RoomView.map;

  void _openRoom(Room room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => RoomDetailPage(
              roomRepository: widget.repository,
              maintenanceLogRepository: widget.maintenanceLogRepository,
              roomId: room.id,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rooms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Map view',
            color:
                _view == _RoomView.map
                    ? AppColors.primary
                    : AppColors.onSurfaceMuted,
            onPressed: () => setState(() => _view = _RoomView.map),
          ),
          IconButton(
            icon: const Icon(Icons.view_list_rounded),
            tooltip: 'List view',
            color:
                _view == _RoomView.list
                    ? AppColors.primary
                    : AppColors.onSurfaceMuted,
            onPressed: () => setState(() => _view = _RoomView.list),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Room>>(
        stream: widget.repository.watchRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms yet.'));
          }
          return _view == _RoomView.map
              ? _RoomsMap(rooms: rooms, onTapRoom: _openRoom)
              : _RoomsList(rooms: rooms, onTapRoom: _openRoom);
        },
      ),
    );
  }
}

class _RoomAction {
  const _RoomAction(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}

bool _isOccupied(Room room) => room.tenantName?.isNotEmpty ?? false;

List<_RoomAction> _pendingActions(Room room) {
  final actions = <_RoomAction>[];
  if (!_isOccupied(room)) return actions;

  final now = DateTime.now();

  final due = room.payment.nextDueDate;
  if (due != null) {
    final days = due.difference(now).inDays;
    if (days < 0) {
      actions.add(
        const _RoomAction(Icons.payments_outlined, 'Overdue', AppColors.danger),
      );
    } else if (days <= AppConfig.paymentDueSoonDays) {
      actions.add(
        _RoomAction(
          Icons.payments_outlined,
          'Due in ${days}d',
          AppColors.warning,
        ),
      );
    }
  }

  final m = room.maintenance;

  final bathroomCutoff = now.subtract(Duration(days: AppConfig.bathroomDueDays));
  final airConCutoff = now.subtract(Duration(days: AppConfig.airConDueDays));
  final generalCutoff = now.subtract(Duration(days: AppConfig.maintenanceDueDays));

  final isBathroomDue = m.lastBathroomClean == null || m.lastBathroomClean!.isBefore(bathroomCutoff);
  final isAirConDue = m.lastAirConClean == null || m.lastAirConClean!.isBefore(airConCutoff);
  final isGeneralDue = [
    m.lastLightBulbMain,
    m.lastLightBulbBath,
    m.lastPaintWalls,
    m.lastReplaceToiletFaucet,
    m.lastReplaceShowerHead,
    m.lastWashCurtain,
    m.lastWashBed
  ].any((date) => date == null || date.isBefore(generalCutoff));

  final maintenanceDue = isBathroomDue || isAirConDue || isGeneralDue;
  if (maintenanceDue) {
    actions.add(
      const _RoomAction(Icons.build_outlined, 'Maintenance', AppColors.warning),
    );
  }

  return actions;
}

/// Fixed building layout: A rooms on floor 1, B (left) and C (right)
/// rooms on floor 2, flanking a central corridor.
class _FloorLayout {
  const _FloorLayout({
    required this.label,
    required this.left,
    required this.right,
  });

  final String label;
  final List<String> left;
  final List<String> right;
}

const _floorLayouts = [
  _FloorLayout(
    label: 'Floor 1',
    left: ['5A', '6A', '7A'],
    right: ['4A', '3A', '2A', '1A'],
  ),
  _FloorLayout(
    label: 'Floor 2',
    left: ['1B', '2B', '3B', '4B', '5B', '6B'],
    right: ['1C', '2C', '3C', '4C', '5C', '6C'],
  ),
];

class _RoomsMap extends StatelessWidget {
  const _RoomsMap({required this.rooms, required this.onTapRoom});

  final List<Room> rooms;
  final void Function(Room room) onTapRoom;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final room in rooms) room.id: room};
    final layoutIds = {
      for (final floor in _floorLayouts) ...floor.left,
      for (final floor in _floorLayouts) ...floor.right,
    };
    final others = rooms.where((r) => !layoutIds.contains(r.id)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final floor in _floorLayouts) ...[
          _MapSectionLabel(floor.label),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (final id in floor.left) _buildCell(byId[id], id),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _Corridor(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          for (final id in floor.right)
                            _buildCell(byId[id], id),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (others.isNotEmpty) ...[
          const _MapSectionLabel('Other rooms'),
          for (final room in others)
            _RoomListTile(room: room, onTap: () => onTapRoom(room)),
        ],
      ],
    );
  }

  Widget _buildCell(Room? room, String id) {
    if (room == null) return _MissingRoomCell(id: id);
    return _RoomMapCell(room: room, onTap: () => onTapRoom(room));
  }
}

class _MapSectionLabel extends StatelessWidget {
  const _MapSectionLabel(this.text);

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

/// The corridor lane between the two room columns.
class _Corridor extends StatelessWidget {
  const _Corridor();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
    );
  }
}

/// A room cell on the map: lit green when occupied, yellow when it has
/// pending actions, fading gray when unoccupied.
class _RoomMapCell extends StatelessWidget {
  const _RoomMapCell({required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = _isOccupied(room);
    final actions = _pendingActions(room);
    final hasActions = actions.isNotEmpty;
    final color =
        hasActions
            ? AppColors.warning
            : occupied
            ? AppColors.success
            : AppColors.onSurfaceMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: occupied ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: occupied ? 0.6 : 0.25),
              width: occupied ? 1.5 : 1,
            ),
            boxShadow:
                occupied && !hasActions
                    ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.id,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            occupied
                                ? AppColors.onSurface
                                : AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                  Icon(
                    hasActions
                        ? Icons.warning_amber_rounded
                        : occupied
                        ? Icons.person
                        : Icons.person_outline,
                    size: 14,
                    color: color,
                  ),
                ],
              ),
              Text(
                occupied ? room.tenantName! : 'Unoccupied',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      occupied ? AppColors.onSurface : AppColors.onSurfaceMuted,
                ),
              ),
              if (hasActions)
                Text(
                  actions.first.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: actions.first.color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for a layout slot with no matching room document.
class _MissingRoomCell extends StatelessWidget {
  const _MissingRoomCell({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.onSurfaceMuted.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                id,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ),
            Text(
              'No data',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomsList extends StatelessWidget {
  const _RoomsList({required this.rooms, required this.onTapRoom});

  final List<Room> rooms;
  final void Function(Room room) onTapRoom;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder:
          (context, index) => _RoomListTile(
            room: rooms[index],
            onTap: () => onTapRoom(rooms[index]),
          ),
    );
  }
}

class _RoomListTile extends StatelessWidget {
  const _RoomListTile({required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = _isOccupied(room);
    final actions = _pendingActions(room);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Text(
            room.id,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(
          occupied ? room.tenantName! : 'Unoccupied',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: occupied ? null : AppColors.onSurfaceMuted,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.phone_outlined,
                text: room.phoneNumber ?? '—',
              ),
              _InfoRow(
                icon: Icons.directions_car_outlined,
                text: room.vehiclePlate ?? room.phoneNumber ?? '—',
              ),
            ],
          ),
        ),
        trailing:
            actions.isEmpty
                ? null
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final action in actions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _ActionChip(action: action),
                      ),
                  ],
                ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action});

  final _RoomAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: action.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(action.icon, size: 12, color: action.color),
          const SizedBox(width: 4),
          Text(
            action.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: action.color,
            ),
          ),
        ],
      ),
    );
  }
}
