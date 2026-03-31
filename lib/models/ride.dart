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
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] ?? json['rideId'] ?? 'RD-000',
      bikeId: json['bikeId'] ?? 'CBR-000',
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      distanceKm: ((json['distanceKm'] ?? json['distance'] ?? 0.0) as num).toDouble(),
      cost: ((json['cost'] ?? json['amount'] ?? 0.0) as num).toDouble(),
      status: json['status'] ?? 'completed',
      fromStation: json['fromStation'] ?? json['station'] ?? 'Unknown',
      toStation: json['toStation'] ?? '',
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  static List<Ride> sampleRides() {
    return [
      Ride(id: 'RD-1021', bikeId: 'CBR-001', startTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)), endTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)), distanceKm: 2.3, cost: 10.0, status: 'completed', fromStation: 'Academic Block A', toStation: 'Hostel 1 Stand'),
      Ride(id: 'RD-1020', bikeId: 'CBR-003', startTime: DateTime.now().subtract(const Duration(days: 3, hours: 5)), endTime: DateTime.now().subtract(const Duration(days: 3, hours: 4)), distanceKm: 1.8, cost: 10.0, status: 'completed', fromStation: 'Library Gate', toStation: 'Sports Complex'),
      Ride(id: 'RD-1019', bikeId: 'CBR-002', startTime: DateTime.now().subtract(const Duration(days: 5)), endTime: DateTime.now().subtract(const Duration(days: 4, hours: 23)), distanceKm: 3.1, cost: 20.0, status: 'completed', fromStation: 'Hostel 1 Stand', toStation: 'Admin Building'),
      Ride(id: 'RD-1018', bikeId: 'CBR-005', startTime: DateTime.now().subtract(const Duration(days: 7, hours: 3)), endTime: DateTime.now().subtract(const Duration(days: 7, hours: 2)), distanceKm: 1.5, cost: 10.0, status: 'completed', fromStation: 'Mess Block', toStation: 'Library Gate'),
      Ride(id: 'RD-1017', bikeId: 'CBR-004', startTime: DateTime.now().subtract(const Duration(days: 10, hours: 1)), endTime: DateTime.now().subtract(const Duration(days: 9, hours: 23)), distanceKm: 4.2, cost: 16.0, status: 'completed', fromStation: 'Sports Complex', toStation: 'Academic Block A'),
    ];
  }
}
