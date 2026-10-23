import 'package:flutter/material.dart';

import '../repositories/firestore/firestore_building_maintenance_repository.dart';
import '../repositories/firestore/firestore_maintenance_log_repository.dart';
import '../repositories/firestore/firestore_room_repository.dart';
import '../repositories/firestore/firestore_staff_repository.dart';
import 'home_page.dart';
import 'maintenance_page.dart';
import 'rooms_page.dart';
import 'staff_page.dart';

/// App shell: bottom navigation with four tabs. Each tab is its own
/// Scaffold with its own app bar; only the Home tab shows the
/// app title + settings action.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  late final List<Widget> _pages = [
    HomePage(
      roomRepository: FirestoreRoomRepository(),
      maintenanceRepository: FirestoreBuildingMaintenanceRepository(),
      staffRepository: FirestoreStaffRepository(),
      onOpenRooms: () => _goToTab(1),
      onOpenMaintenance: () => _goToTab(2),
      onOpenStaff: () => _goToTab(3),
    ),
    RoomsPage(
      repository: FirestoreRoomRepository(),
      maintenanceLogRepository: FirestoreMaintenanceLogRepository(),
    ),
    MaintenancePage(
      repository: FirestoreMaintenanceLogRepository(),
      roomRepository: FirestoreRoomRepository(),
    ),
    StaffPage(repository: FirestoreStaffRepository()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Room',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Maintenance',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Staff',
          ),
        ],
      ),
    );
  }
}
