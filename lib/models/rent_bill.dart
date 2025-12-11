class RentBill {
  final String id;
  final String monthYear;
  final String billingDateBs;
  final int previousReading;
  final int currentReading;
  final int units;
  final double costPerUnit;
  final double electricityBill;
  final double waterCharge;
  final double baseRent;
  final double total;
  final DateTime createdAt;

  RentBill({
    required this.id,
    required this.monthYear,
    required this.billingDateBs,
    required this.previousReading,
    required this.currentReading,
    required this.units,
    required this.costPerUnit,
    required this.electricityBill,
    required this.waterCharge,
    required this.baseRent,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'monthYear': monthYear,
    'billingDateBs': billingDateBs,
    'previousReading': previousReading,
    'currentReading': currentReading,
    'units': units,
    'costPerUnit': costPerUnit,
    'electricityBill': electricityBill,
    'waterCharge': waterCharge,
    'baseRent': baseRent,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RentBill.fromMap(Map<String, dynamic> map) => RentBill(
    id: map['id'],
    monthYear: map['monthYear'],
    billingDateBs: map['billingDateBs'],
    previousReading: map['previousReading'],
    currentReading: map['currentReading'],
    units: map['units'],
    costPerUnit: (map['costPerUnit'] as num).toDouble(),
    electricityBill: (map['electricityBill'] as num).toDouble(),
    waterCharge: (map['waterCharge'] as num).toDouble(),
    baseRent: (map['baseRent'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    createdAt: DateTime.parse(map['createdAt']),
  );
}
