import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/building_maintenance.dart';
import '../building_maintenance_repository.dart';

class FirestoreBuildingMaintenanceRepository
    implements BuildingMaintenanceRepository {
  FirestoreBuildingMaintenanceRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _globalStats =>
      _db.collection('building_maintenance').doc('global_stats');

  @override
  Stream<BuildingMaintenance?> watchGlobalStats() {
    return _globalStats.snapshots().map(
          (doc) => doc.exists
              ? BuildingMaintenance.fromDoc(doc.data()!, doc.id)
              : null,
        );
  }

  @override
  Future<BuildingMaintenance?> getGlobalStats() async {
    final doc = await _globalStats.get();
    if (!doc.exists) return null;
    return BuildingMaintenance.fromDoc(doc.data()!, doc.id);
  }

  @override
  Future<void> createGlobalStats(BuildingMaintenance stats) {
    return _globalStats.set(stats.toData());
  }

  @override
  Future<void> updateGlobalStats(BuildingMaintenance stats) {
    return _globalStats.update(stats.toData());
  }
}
