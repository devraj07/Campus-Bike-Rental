import '../models/bike.dart';
import '../models/bike_state.dart';
import '../models/ride.dart';
import '../utils/code_generator.dart';

class ApiService {
  static const String baseUrl = 'https://api.campusbike.iitgn.ac.in';

  // Simulate network delay
  Future<void> _delay([int ms = 800]) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  Future<List<Bike>> fetchAvailableBikes({String? query}) async {
    await _delay();
    final bikes = Bike.sampleBikes();
    if (query != null && query.isNotEmpty) {
      return bikes
          .where((b) =>
              b.id.toLowerCase().contains(query.toLowerCase()) ||
              b.station.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    return bikes;
  }

  Future<List<Ride>> fetchRideHistory(String userId) async {
    await _delay();
    return Ride.sampleRides();
  }

  Future<Map<String, dynamic>> startRide(String bikeId) async {
    await _delay();
    return {
      'rideId': 'RD-${DateTime.now().millisecondsSinceEpoch}',
      'pin': generate4DigitCode(),
      'startTime': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> endRide(String rideId) async {
    await _delay();
    return {
      'rideId': rideId,
      'endTime': DateTime.now().toIso8601String(),
      'distanceKm': 2.4,
      'cost': 20.0,
      'durationMinutes': 45,
    };
  }

  Future<bool> processPayment({
    required String rideId,
    required double amount,
    required String method,
  }) async {
    await _delay(1200);
    return true;
  }

  Future<bool> submitBikeListing({
    required String bikeId,
    required String station,
    String? imagePath,
  }) async {
    await _delay();
    return true;
  }

  Future<List<StandAvailability>> fetchStands() async {
    await _delay();
    return StandAvailability.sampleStands();
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    await _delay();
    return {
      'name': 'Devraj Rawat',
      'email': 'devraj.rawat@iitgn.ac.in',
      'totalRides': 5,
      'totalSpent': 66.0,
      'co2SavedGrams': 2.7,
      'walletBalance': 120.0,
    };
  }
}
