import 'package:cloud_firestore/cloud_firestore.dart';

class RoomMaintenance {
  const RoomMaintenance({
    this.lastBathroomClean,
    this.lastAirConClean,
    this.lastLightBulbMain,
    this.lastLightBulbBath,
    this.lastPaintWalls,
    this.lastReplaceToiletFaucet,
    this.lastReplaceShowerHead,
    this.lastWashCurtain,
    this.lastWashBed
  });

  final DateTime? lastBathroomClean;
  final DateTime? lastAirConClean;
  final DateTime? lastLightBulbMain;
  final DateTime? lastLightBulbBath;
  final DateTime? lastPaintWalls;
  final DateTime? lastReplaceToiletFaucet;
  final DateTime? lastReplaceShowerHead;
  final DateTime? lastWashCurtain;
  final DateTime? lastWashBed;

  factory RoomMaintenance.fromData(Map<String, dynamic> data) {
    return RoomMaintenance(
      lastBathroomClean: (data['lastBathroomClean'] as Timestamp?)?.toDate(),
      lastAirConClean: (data['lastAirConClean'] as Timestamp?)?.toDate(),
      lastLightBulbMain: (data['lastLightBulbMain'] as Timestamp?)?.toDate(),
      lastLightBulbBath: (data['lastLightBulbBath'] as Timestamp?)?.toDate(),
      lastPaintWalls: (data['lastPaintWalls'] as Timestamp?)?.toDate(),
      lastReplaceToiletFaucet: (data['lastReplaceToiletFaucet'] as Timestamp?)?.toDate(),
      lastReplaceShowerHead: (data['lastReplaceShowerHead'] as Timestamp?)?.toDate(),
      lastWashCurtain: (data['lastWashCurtain'] as Timestamp?)?.toDate(),
      lastWashBed: (data['lastWashBed'] as Timestamp?)?.toDate()
    );
  }

  Map<String, dynamic> toData() {
    return {
      if (lastBathroomClean != null)
        'lastBathroomClean': Timestamp.fromDate(lastBathroomClean!),
      if (lastAirConClean != null)
        'lastAirConClean': Timestamp.fromDate(lastAirConClean!),
      if (lastLightBulbMain != null)
        'lastLightBulbMain': Timestamp.fromDate(lastLightBulbMain!),
      if (lastLightBulbBath != null)
        'lastLightBulbBath': Timestamp.fromDate(lastLightBulbBath!),
      if (lastPaintWalls != null)
        'lastPaintWalls': Timestamp.fromDate(lastPaintWalls!),
      if (lastReplaceToiletFaucet != null)
        'lastReplaceToiletFaucet': Timestamp.fromDate(lastReplaceToiletFaucet!),
      if (lastReplaceShowerHead != null)
        'lastReplaceShowerHead': Timestamp.fromDate(lastReplaceShowerHead!),
      if (lastWashCurtain != null)
        'lastWashCurtain': Timestamp.fromDate(lastWashCurtain!),
      if (lastWashBed != null)
        'lastWashBed': Timestamp.fromDate(lastWashBed!),
    };
  }
}

class RoomPayment {
  const RoomPayment({
    this.lastPaidDate,
    this.amountPaid,
    this.nextDueDate,
  });

  final DateTime? lastPaidDate;
  final int? amountPaid;
  final DateTime? nextDueDate;

  factory RoomPayment.fromData(Map<String, dynamic> data) {
    return RoomPayment(
      lastPaidDate: (data['lastPaidDate'] as Timestamp?)?.toDate(),
      amountPaid: (data['amountPaid'] as num?)?.toInt(),
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toData() {
    return {
      if (lastPaidDate != null) 'lastPaidDate': Timestamp.fromDate(lastPaidDate!),
      if (amountPaid != null) 'amountPaid': amountPaid,
      if (nextDueDate != null) 'nextDueDate': Timestamp.fromDate(nextDueDate!),
    };
  }
}

class Room {
  const Room({
    required this.id,
    required this.type,
    required this.pricePer6Months,
    this.tenantName,
    this.phoneNumber,
    this.guardianContact,
    this.vehiclePlate,
    this.checkInDate,
    this.maintenance = const RoomMaintenance(),
    this.payment = const RoomPayment(),
  });

  final String id;
  final String type;
  final int pricePer6Months;
  final String? tenantName;
  final String? phoneNumber;
  final String? guardianContact;
  final String? vehiclePlate;
  final DateTime? checkInDate;
  final RoomMaintenance maintenance;
  final RoomPayment payment;

  factory Room.fromDoc(Map<String, dynamic> data, String id) {
    return Room(
      id: id,
      type: data['type'] as String? ?? '',
      pricePer6Months: (data['pricePer6Months'] as num?)?.toInt() ?? 0,
      tenantName: data['tenantName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      guardianContact: data['guardianContact'] as String?,
      vehiclePlate: data['vehiclePlate'] as String?,
      checkInDate: (data['checkInDate'] as Timestamp?)?.toDate(),
      maintenance: RoomMaintenance.fromData(
        (data['maintenance'] as Map<String, dynamic>?) ?? const {},
      ),
      payment: RoomPayment.fromData(
        (data['payment'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toData() {
    return {
      'type': type,
      'pricePer6Months': pricePer6Months,
      if (tenantName != null) 'tenantName': tenantName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (guardianContact != null) 'guardianContact': guardianContact,
      if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
      if (checkInDate != null) 'checkInDate': Timestamp.fromDate(checkInDate!),
      'maintenance': maintenance.toData(),
      'payment': payment.toData(),
    };
  }
}
