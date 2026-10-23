import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/room.dart';
import '../room_repository.dart';

class FirestoreRoomRepository implements RoomRepository {
  FirestoreRoomRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');

  @override
  Stream<List<Room>> watchRooms() {
    return _rooms
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Room.fromDoc(doc.data(), doc.id))
                  .toList(),
        );
  }

  @override
  Future<List<Room>> getRooms() async {
    final snapshot = await _rooms.orderBy(FieldPath.documentId).get();
    return snapshot.docs
        .map((doc) => Room.fromDoc(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Room?> getRoom(String id) async {
    final doc = await _rooms.doc(id).get();
    if (!doc.exists) return null;
    return Room.fromDoc(doc.data()!, doc.id);
  }

  @override
  Future<void> addRoom(String id, Room room) {
    return _rooms.doc(id).set(room.toData());
  }

  @override
  Future<void> updateRoom(String id, Room room) {
    return _rooms.doc(id).update({
      ...room.toData(),
      if (room.tenantName == null) 'tenantName': FieldValue.delete(),
      if (room.phoneNumber == null) 'phoneNumber': FieldValue.delete(),
      if (room.guardianContact == null) 'guardianContact': FieldValue.delete(),
      if (room.vehiclePlate == null) 'vehiclePlate': FieldValue.delete(),
    });
  }

  @override
  Future<void> deleteRoom(String id) {
    return _rooms.doc(id).delete();
  }
}
