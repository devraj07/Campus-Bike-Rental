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

  factory OwnerEarnings.fromRecords(
    List<BikeRentalRecord> records, {
    double withdrawnEarnings = 0.0,
  }) {
    final total = records.fold(0.0, (sum, r) => sum + r.earnings);
    final pending = (total - withdrawnEarnings).clamp(0.0, double.infinity);
    return OwnerEarnings(
      totalRentals: records.length,
      totalEarnings: total,
      withdrawn: withdrawnEarnings,
      pendingWithdrawal: pending,
    );
  }
}
