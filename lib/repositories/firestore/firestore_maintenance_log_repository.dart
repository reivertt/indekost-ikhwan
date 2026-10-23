import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/maintenance_log.dart';
import '../maintenance_log_repository.dart';

class FirestoreMaintenanceLogRepository implements MaintenanceLogRepository {
  FirestoreMaintenanceLogRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('maintenance_logs');

  DocumentReference<Map<String, dynamic>> get _globalStats =>
      _db.collection('building_maintenance').doc('global_stats');

  @override
  Stream<List<MaintenanceLog>> watchLogs() {
    return _logs
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MaintenanceLog.fromDoc(doc.data(), doc.id))
                  .toList(),
        );
  }

  @override
  Stream<List<MaintenanceLog>> watchRoomLogs(String roomId) {
    return _logs.where('roomId', isEqualTo: roomId).snapshots().map((snapshot) {
      final logs =
          snapshot.docs
              .map((doc) => MaintenanceLog.fromDoc(doc.data(), doc.id))
              .toList();
      logs.sort((a, b) => b.date.compareTo(a.date));
      return logs;
    });
  }

  @override
  Future<void> addLog(MaintenanceLog log) async {
    await _logs.add(log.toData());
    await _syncLastDone(log);
  }

  @override
  Future<void> updateLog(String id, MaintenanceLog log) async {
    await _logs.doc(id).update({
      ...log.toData(),
      if (log.notes == null || log.notes!.isEmpty) 'notes': FieldValue.delete(),
      if (log.amount == null) 'amount': FieldValue.delete(),
    });
    await _syncLastDone(log);
  }

  @override
  Future<void> deleteLog(String id) {
    return _logs.doc(id).delete();
  }

  Future<void> _syncLastDone(MaintenanceLog log) async {
    final timestamp = Timestamp.fromDate(log.date);
    if (log.scope == MaintenanceScope.room && log.roomId != null) {
      final field = switch (log.category) {
        MaintenanceCategory.bathroom => 'maintenance.lastBathroomClean',
        MaintenanceCategory.airCon => 'maintenance.lastAirConClean',
        MaintenanceCategory.lightBulbMain => 'maintenance.lastLightBulbMain',
        MaintenanceCategory.lightBulbBath => 'maintenance.lastLightBulbBath',
        _ => null,
      };
      if (field != null) {
        await _db.collection('rooms').doc(log.roomId).update({
          field: timestamp,
        });
      }
      return;
    }
    if (log.scope == MaintenanceScope.building) {
      switch (log.category) {
        case MaintenanceCategory.water:
          await _globalStats.update({'waterLastCleaned': timestamp});
        case MaintenanceCategory.septic:
          await _globalStats.update({'septicLastCleaned': timestamp});
        case MaintenanceCategory.electricity:
          await _globalStats.update({
            'electricity.lastTokenDate': timestamp,
            if (log.amount != null) 'electricity.lastTokenAmount': log.amount,
          });
        default:
          break;
      }
    }
  }
}
