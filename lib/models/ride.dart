class Ride {
  final String id;
  final String bikeId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final double cost;
  final String status;
  final String fromStation;
  final String toStation;
  final String renterName;
  final String paymentStatus;

  const Ride({
    required this.id,
    required this.bikeId,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.cost,
    required this.status,
    required this.fromStation,
    this.toStation = '',
    this.renterName = '',
    this.paymentStatus = '',
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
}
