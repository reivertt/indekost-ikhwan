import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:indekost_ikhwan/models/maintenance_log.dart';
import 'package:indekost_ikhwan/models/room.dart';

void main() {
  group('Room.fromDoc', () {
    test('maps a full document to a Room', () {
      final now = DateTime.now();
      final room = Room.fromDoc({
        'type': 'Standard',
        'pricePer6Months': 10500000,
        'tenantName': 'John Doe',
        'phoneNumber': '+6281234567890',
        'guardianContact': '+6280987654321',
        'vehiclePlate': 'L 1234 AB',
        'checkInDate': Timestamp.fromDate(now),
        'maintenance': {
          'lastBathroomClean': Timestamp.fromDate(now),
          'lastAirConClean': Timestamp.fromDate(now),
        },
        'payment': {
          'lastPaidDate': Timestamp.fromDate(now),
          'amountPaid': 10500000,
          'nextDueDate': Timestamp.fromDate(now),
        },
      }, '1A');

      expect(room.id, '1A');
      expect(room.type, 'Standard');
      expect(room.pricePer6Months, 10500000);
      expect(room.tenantName, 'John Doe');
      expect(room.phoneNumber, '+6281234567890');
      expect(room.guardianContact, '+6280987654321');
      expect(room.vehiclePlate, 'L 1234 AB');
      expect(room.checkInDate, now);
      expect(room.maintenance.lastBathroomClean, now);
      expect(room.maintenance.lastAirConClean, now);
      expect(room.payment.amountPaid, 10500000);
      expect(room.payment.nextDueDate, now);
    });

    test('defaults when fields are missing', () {
      final room = Room.fromDoc({}, '1A');

      expect(room.type, '');
      expect(room.pricePer6Months, 0);
      expect(room.tenantName, isNull);
      expect(room.maintenance.lastBathroomClean, isNull);
      expect(room.payment.amountPaid, isNull);
    });
  });

  group('Room.toData', () {
    test('round-trips through fromDoc', () {
      final original = Room(
        id: '2C',
        type: 'Large',
        pricePer6Months: 11500000,
        checkInDate: DateTime(2026, 8, 1),
        maintenance: const RoomMaintenance(
          lastAirConClean: null,
          lastBathroomClean: null,
          lastLightBulbMain: null,
          lastLightBulbBath: null,
        ),
      );

      final restored = Room.fromDoc(original.toData(), '2C');

      expect(restored.id, '2C');
      expect(restored.type, 'Large');
      expect(restored.pricePer6Months, 11500000);
      expect(restored.checkInDate, DateTime(2026, 8, 1));
    });
  });

  group('MaintenanceLog.fromDoc', () {
    test('maps a full document to a MaintenanceLog', () {
      final now = DateTime.now();
      final log = MaintenanceLog.fromDoc({
        'scope': 'room',
        'category': 'airCon',
        'date': Timestamp.fromDate(now),
        'roomId': '1A',
        'notes': 'Filter replaced',
        'amount': 50000,
      }, 'log1');

      expect(log.id, 'log1');
      expect(log.scope, MaintenanceScope.room);
      expect(log.category, MaintenanceCategory.airCon);
      expect(log.date, now);
      expect(log.roomId, '1A');
      expect(log.notes, 'Filter replaced');
      expect(log.amount, 50000);
    });

    test('defaults when fields are missing', () {
      final log = MaintenanceLog.fromDoc({}, 'log1');

      expect(log.scope, MaintenanceScope.building);
      expect(log.category, MaintenanceCategory.other);
      expect(log.roomId, isNull);
      expect(log.notes, isNull);
      expect(log.amount, isNull);
    });
  });

  group('MaintenanceLog.toData', () {
    test('round-trips through fromDoc', () {
      final original = MaintenanceLog(
        id: 'log1',
        scope: MaintenanceScope.building,
        category: MaintenanceCategory.electricity,
        date: DateTime(2026, 8, 1),
        amount: 100000,
      );

      final restored = MaintenanceLog.fromDoc(original.toData(), 'log1');

      expect(restored.id, 'log1');
      expect(restored.scope, MaintenanceScope.building);
      expect(restored.category, MaintenanceCategory.electricity);
      expect(restored.date, DateTime(2026, 8, 1));
      expect(restored.amount, 100000);
    });

    test('categoriesForScope filters by scope and keeps other', () {
      final room = categoriesForScope(MaintenanceScope.room);
      expect(room, contains(MaintenanceCategory.bathroom));
      expect(room, contains(MaintenanceCategory.other));
      expect(room, isNot(contains(MaintenanceCategory.water)));

      final building = categoriesForScope(MaintenanceScope.building);
      expect(building, contains(MaintenanceCategory.water));
      expect(building, contains(MaintenanceCategory.other));
      expect(building, isNot(contains(MaintenanceCategory.airCon)));
    });
  });
}
