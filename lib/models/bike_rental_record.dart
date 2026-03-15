class BikeRentalRecord {
  final String id;
  final String bikeId;
  final String rentedBy;
  final DateTime date;
  final Duration duration;
  final double earnings;

  const BikeRentalRecord({
    required this.id,
    required this.bikeId,
    required this.rentedBy,
    required this.date,
    required this.duration,
    required this.earnings,
  });

  static List<BikeRentalRecord> sampleRecords() {
    return [
      BikeRentalRecord(
        id: 'ORH-001',
        bikeId: 'B201',
        rentedBy: 'Rahul Shah',
        date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        duration: const Duration(minutes: 45),
        earnings: 18.0,
      ),
      BikeRentalRecord(
        id: 'ORH-002',
        bikeId: 'B201',
        rentedBy: 'Priya Mehta',
        date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
        duration: const Duration(hours: 1, minutes: 20),
        earnings: 26.0,
      ),
      BikeRentalRecord(
        id: 'ORH-003',
        bikeId: 'B201',
        rentedBy: 'Arjun Patel',
        date: DateTime.now().subtract(const Duration(days: 4)),
        duration: const Duration(minutes: 30),
        earnings: 10.0,
      ),
      BikeRentalRecord(
        id: 'ORH-004',
        bikeId: 'B201',
        rentedBy: 'Sneha Joshi',
        date: DateTime.now().subtract(const Duration(days: 6, hours: 2)),
        duration: const Duration(hours: 2),
        earnings: 20.0,
      ),
      BikeRentalRecord(
        id: 'ORH-005',
        bikeId: 'B201',
        rentedBy: 'Karan Verma',
        date: DateTime.now().subtract(const Duration(days: 8)),
        duration: const Duration(minutes: 55),
        earnings: 18.0,
      ),
    ];
  }
}

class OwnerEarnings {
  final int totalRentals;
  final double totalEarnings;
  final double pendingWithdrawal;
  final double withdrawn;

  const OwnerEarnings({
    required this.totalRentals,
    required this.totalEarnings,
    required this.pendingWithdrawal,
    required this.withdrawn,
  });

  factory OwnerEarnings.fromRecords(List<BikeRentalRecord> records) {
    final total = records.fold(0.0, (sum, r) => sum + r.earnings);
    return OwnerEarnings(
      totalRentals: records.length,
      totalEarnings: total,
      pendingWithdrawal: total * 0.6,
      withdrawn: total * 0.4,
    );
  }
}
