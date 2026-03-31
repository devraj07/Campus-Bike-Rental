class Bike {
  final String id;
  final String station;
  final bool isAvailable;
  final int batteryLevel;
  final double pricePerHour;
  final String imageUrl;
  final String type;
  final double distanceKm;

  const Bike({
    required this.id,
    required this.station,
    required this.isAvailable,
    required this.batteryLevel,
    required this.pricePerHour,
    this.imageUrl = '',
    this.type = 'Electric',
    this.distanceKm = 0.0,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] ?? json['bikeId'] ?? 'CBR-000',
      station: json['station'] ?? json['standName'] ?? 'Unknown Stand',
      isAvailable: json['isAvailable'] ?? json['available'] ?? true,
      batteryLevel: ((json['batteryLevel'] ?? json['battery'] ?? 80) as num).toInt(),
      pricePerHour: ((json['pricePerHour'] ?? json['price'] ?? 10.0) as num).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? 'Electric',
      distanceKm: ((json['distanceKm'] ?? json['distance'] ?? 0.0) as num).toDouble(),
    );
  }

  static List<Bike> sampleBikes() {
    return const [
      Bike(id: 'CBR-001', station: 'Academic Block A', isAvailable: true, batteryLevel: 85, pricePerHour: 10.0, type: 'Electric', distanceKm: 0.2),
      Bike(id: 'CBR-002', station: 'Hostel 1 Stand', isAvailable: true, batteryLevel: 62, pricePerHour: 10.0, type: 'Electric', distanceKm: 0.5),
      Bike(id: 'CBR-003', station: 'Library Gate', isAvailable: false, batteryLevel: 90, pricePerHour: 10.0, type: 'Electric', distanceKm: 0.8),
      Bike(id: 'CBR-004', station: 'Sports Complex', isAvailable: true, batteryLevel: 45, pricePerHour: 8.0, type: 'Manual', distanceKm: 1.1),
      Bike(id: 'CBR-005', station: 'Mess Block', isAvailable: true, batteryLevel: 78, pricePerHour: 10.0, type: 'Electric', distanceKm: 1.4),
      Bike(id: 'CBR-006', station: 'Admin Building', isAvailable: false, batteryLevel: 30, pricePerHour: 8.0, type: 'Manual', distanceKm: 1.7),
    ];
  }
}
