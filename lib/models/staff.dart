import 'package:cloud_firestore/cloud_firestore.dart';

class WorkLog {
  const WorkLog({
    required this.id,
    required this.date,
    required this.hoursWorked,
    required this.tasksCompleted,
    required this.totalPay,
  });

  final String id;
  final DateTime date;
  final int hoursWorked;
  final String tasksCompleted;
  final int totalPay;

  factory WorkLog.fromDoc(Map<String, dynamic> data, String id) {
    return WorkLog(
      id: id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hoursWorked: (data['hoursWorked'] as num?)?.toInt() ?? 0,
      tasksCompleted: data['tasksCompleted'] as String? ?? '',
      totalPay: (data['totalPay'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toData() {
    return {
      'date': Timestamp.fromDate(date),
      'hoursWorked': hoursWorked,
      'tasksCompleted': tasksCompleted,
      'totalPay': totalPay,
    };
  }
}

class Staff {
  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.payRatePerMonth,
    required this.isActive,
    this.phoneNumber,
  });

  final String id;
  final String name;
  final String role;
  final int payRatePerMonth;
  final bool isActive;
  final String? phoneNumber;

  factory Staff.fromDoc(Map<String, dynamic> data, String id) {
    return Staff(
      id: id,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      payRatePerMonth: (data['payRatePerMonth'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toData() {
    return {
      'name': name,
      'role': role,
      'payRatePerMonth': payRatePerMonth,
      'isActive': isActive,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}
