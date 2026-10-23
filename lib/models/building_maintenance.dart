import 'package:cloud_firestore/cloud_firestore.dart';

class ElectricityStats {
  const ElectricityStats({
    this.lastTokenDate,
    this.lastTokenAmount,
    this.tokenBeforeRefill,
  });

  final DateTime? lastTokenDate;
  final int? lastTokenAmount;
  final double? tokenBeforeRefill;

  factory ElectricityStats.fromData(Map<String, dynamic> data) {
    return ElectricityStats(
      lastTokenDate: (data['lastTokenDate'] as Timestamp?)?.toDate(),
      lastTokenAmount: (data['lastTokenAmount'] as num?)?.toInt(),
      tokenBeforeRefill: (data['tokenBeforeRefill'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toData() {
    return {
      if (lastTokenDate != null) 'lastTokenDate': Timestamp.fromDate(lastTokenDate!),
      if (lastTokenAmount != null) 'lastTokenAmount': lastTokenAmount,
      if (tokenBeforeRefill != null) 'tokenBeforeRefill': tokenBeforeRefill,
    };
  }
}

class BuildingMaintenance {
  const BuildingMaintenance({
    required this.id,
    this.waterLastCleaned,
    this.septicLastCleaned,
    this.electricity = const ElectricityStats(),
  });

  final String id;
  final DateTime? waterLastCleaned;
  final DateTime? septicLastCleaned;
  final ElectricityStats electricity;

  factory BuildingMaintenance.fromDoc(Map<String, dynamic> data, String id) {
    return BuildingMaintenance(
      id: id,
      waterLastCleaned: (data['waterLastCleaned'] as Timestamp?)?.toDate(),
      septicLastCleaned: (data['septicLastCleaned'] as Timestamp?)?.toDate(),
      electricity: ElectricityStats.fromData(
        (data['electricity'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toData() {
    return {
      if (waterLastCleaned != null)
        'waterLastCleaned': Timestamp.fromDate(waterLastCleaned!),
      if (septicLastCleaned != null)
        'septicLastCleaned': Timestamp.fromDate(septicLastCleaned!),
      'electricity': electricity.toData(),
    };
  }
}
