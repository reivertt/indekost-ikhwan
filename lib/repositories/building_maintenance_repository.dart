import '../models/building_maintenance.dart';

/// Abstraction over the `building_maintenance` collection
/// (single `global_stats` document).
abstract interface class BuildingMaintenanceRepository {
  /// Watch the `global_stats` document.
  Stream<BuildingMaintenance?> watchGlobalStats();

  /// Fetch the `global_stats` document once.
  Future<BuildingMaintenance?> getGlobalStats();

  /// Create the `global_stats` document.
  Future<void> createGlobalStats(BuildingMaintenance stats);

  /// Update the `global_stats` document.
  Future<void> updateGlobalStats(BuildingMaintenance stats);
}
