import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/staff.dart';
import '../staff_repository.dart';

class FirestoreStaffRepository implements StaffRepository {
  FirestoreStaffRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _staff =>
      _db.collection('staff');

  CollectionReference<Map<String, dynamic>> _workLogs(String staffId) =>
      _staff.doc(staffId).collection('work_logs');

  @override
  Stream<List<Staff>> watchStaff() {
    return _staff.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Staff.fromDoc(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<List<Staff>> getStaff() async {
    final snapshot = await _staff.get();
    return snapshot.docs
        .map((doc) => Staff.fromDoc(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Staff?> getStaffMember(String id) async {
    final doc = await _staff.doc(id).get();
    if (!doc.exists) return null;
    return Staff.fromDoc(doc.data()!, doc.id);
  }

  @override
  Future<String> addStaff(Staff staff) {
    return _staff.add(staff.toData()).then((doc) => doc.id);
  }

  @override
  Future<void> updateStaff(String id, Staff staff) {
    return _staff.doc(id).update(staff.toData());
  }

  @override
  Future<void> deleteStaff(String id) async {
    final workLogs = await _workLogs(id).get();
    for (final doc in workLogs.docs) {
      await doc.reference.delete();
    }
    await _staff.doc(id).delete();
  }

  @override
  Stream<List<WorkLog>> watchWorkLogs(String staffId) {
    return _workLogs(staffId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkLog.fromDoc(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> addWorkLog(String staffId, WorkLog log) {
    return _workLogs(staffId).add(log.toData());
  }
}
