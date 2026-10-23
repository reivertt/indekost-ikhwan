import '../models/maintenance_log.dart';

/// Abstraction over the `maintenance_logs` collection.
abstract interface class MaintenanceLogRepository {
  /// Watch all logs, newest first.
  Stream<List<MaintenanceLog>> watchLogs();

  /// Watch logs for a specific room, newest first.
  Stream<List<MaintenanceLog>> watchRoomLogs(String roomId);

  /// Add a log entry. Also syncs the matching "last done" field on the
  /// room or building document.
  Future<void> addLog(MaintenanceLog log);

  /// Update a log entry. Also re-syncs the matching "last done" field.
  Future<void> updateLog(String id, MaintenanceLog log);

  /// Delete a log entry by document id.
  Future<void> deleteLog(String id);
}
