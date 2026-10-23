import '../models/room.dart';

/// Abstraction over the Firestore `rooms` collection.
abstract interface class RoomRepository {
  /// Watch all rooms, ordered by document id.
  Stream<List<Room>> watchRooms();

  /// Fetch all rooms once.
  Future<List<Room>> getRooms();

  /// Fetch a single room by its document id (e.g. `1A`).
  Future<Room?> getRoom(String id);

  /// Create a room with the given document id. Throws if it already exists.
  Future<void> addRoom(String id, Room room);

  /// Update a room's tenant/payment/maintenance data.
  Future<void> updateRoom(String id, Room room);

  /// Delete a room by document id.
  Future<void> deleteRoom(String id);
}
