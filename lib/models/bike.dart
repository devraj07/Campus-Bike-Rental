class Bike {
  final String id;
  final String station;
  final bool isAvailable;
  final int batteryLevel;
  final double pricePerHour;
  final String imageUrl;
  final String type;
  final double distanceKm;
  final String ownerName;

  const Bike({
    required this.id,
    required this.station,
    required this.isAvailable,
    required this.batteryLevel,
    required this.pricePerHour,
    this.imageUrl = '',
    this.type = 'Electric',
    this.distanceKm = 0.0,
    this.ownerName = '',
  });
}
