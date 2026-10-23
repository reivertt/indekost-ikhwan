import 'package:cloud_firestore/cloud_firestore.dart';

enum MaintenanceScope { room, building }

enum MaintenanceCategory {
  water,
  septic,
  electricity,
  bathroom,
  airCon,
  lightBulbMain,
  lightBulbBath,
  paintWalls,
  toiletFaucet,
  showerHead,
  washCurtain,
  washBed,
  other,
}

extension MaintenanceCategoryX on MaintenanceCategory {
  MaintenanceScope get scope => switch (this) {
        MaintenanceCategory.water ||
        MaintenanceCategory.septic ||
        MaintenanceCategory.electricity =>
          MaintenanceScope.building,
        MaintenanceCategory.other => MaintenanceScope.building,
        _ => MaintenanceScope.room,
      };
}

/// Categories selectable for a given scope (`other` is valid for both).
List<MaintenanceCategory> categoriesForScope(MaintenanceScope scope) {
  return MaintenanceCategory.values
      .where((c) =>
          c.scope == scope || c == MaintenanceCategory.other)
      .toList();
}

class MaintenanceLog {
  const MaintenanceLog({
    required this.id,
    required this.scope,
    required this.category,
    required this.date,
    this.roomId,
    this.notes,
    this.amount,
  });

  final String id;
  final MaintenanceScope scope;
  final MaintenanceCategory category;
  final DateTime date;
  final String? roomId;
  final String? notes;
  final int? amount;

  factory MaintenanceLog.fromDoc(Map<String, dynamic> data, String id) {
    return MaintenanceLog(
      id: id,
      scope: MaintenanceScope.values.asNameMap()[data['scope']] ??
          MaintenanceScope.building,
      category: MaintenanceCategory.values.asNameMap()[data['category']] ??
          MaintenanceCategory.other,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      roomId: data['roomId'] as String?,
      notes: data['notes'] as String?,
      amount: (data['amount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toData() {
    return {
      'scope': scope.name,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      if (roomId != null) 'roomId': roomId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (amount != null) 'amount': amount,
    };
  }
}
