import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bike.dart';
import '../models/ride.dart';
import '../models/bike_rental_record.dart';

class ApiService {
  static const String baseUrl = 'https://api.campusbike.iitgn.ac.in';

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print('GET error: $e');
      return null;
    }
  }

  Future<dynamic> _post(String endpoint, Map body) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl$endpoint'),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print('POST error: $e');
      return null;
    }
  }

  // Bikes
  Future<List<Bike>> fetchAvailableBikes({String? query}) async {
    final data = await _get('/bikes');
    if (data == null) return Bike.sampleBikes();
    try {
      return (data as List).map((e) => Bike.fromJson(e)).toList();
    } catch (_) {
      return Bike.sampleBikes();
    }
  }

  // Stands - used by StandAvailabilityScreen
  Future<List<Map<String, dynamic>>> fetchStands() async {
    final data = await _get('/stands');
    if (data == null) {
      return [
        {'id': 'STD-001', 'name': 'Academic Block A', 'description': 'Near main entrance', 'totalSlots': 10, 'availableBikes': 4, 'availableBikeIds': ['CBR-001', 'CBR-002']},
        {'id': 'STD-002', 'name': 'Library Gate', 'description': 'Outside library', 'totalSlots': 8, 'availableBikes': 0, 'availableBikeIds': []},
        {'id': 'STD-003', 'name': 'Hostel 1 Stand', 'description': 'Between Hostel 1 and 2', 'totalSlots': 12, 'availableBikes': 3, 'availableBikeIds': ['CBR-003', 'CBR-004']},
        {'id': 'STD-004', 'name': 'Mess Block', 'description': 'Adjacent to central mess', 'totalSlots': 8, 'availableBikes': 2, 'availableBikeIds': ['CBR-005']},
        {'id': 'STD-005', 'name': 'Sports Complex', 'description': 'Near sports gate', 'totalSlots': 6, 'availableBikes': 1, 'availableBikeIds': ['CBR-006']},
        {'id': 'STD-006', 'name': 'Admin Building', 'description': 'Ground floor admin', 'totalSlots': 6, 'availableBikes': 2, 'availableBikeIds': ['CBR-007']},
      ];
    }
    return List<Map<String, dynamic>>.from(data);
  }

  // Rides
  Future<List<Ride>> fetchRideHistory(String userId) async {
    final data = await _get('/rides/$userId');
    if (data == null) return Ride.sampleRides();
    try {
      return (data as List).map((e) => Ride.fromJson(e)).toList();
    } catch (_) {
      return Ride.sampleRides();
    }
  }

  Future<Map<String, dynamic>> startRide(String bikeId) async {
    final res = await _post('/ride/start', {'bikeId': bikeId});
    if (res == null) {
      return {
        'rideId': 'RD-demo',
        'pin': '4823',
        'startTime': DateTime.now().toIso8601String(),
      };
    }
    return Map<String, dynamic>.from(res);
  }

  // Alias used by unlock_pin_screen
  Future<Map<String, dynamic>> startRental(String bikeId, String pin) async {
    return startRide(bikeId);
  }

  Future<Map<String, dynamic>> endRide(String rideId) async {
    final res = await _post('/ride/end', {'rideId': rideId});
    if (res == null) {
      return {
        'rideId': rideId,
        'endTime': DateTime.now().toIso8601String(),
        'distanceKm': 2.4,
        'cost': 20.0,
      };
    }
    return Map<String, dynamic>.from(res);
  }

  // Bike listing
  Future<bool> submitBikeListing({
    required String bikeId,
    required String station,
    String? imagePath,
  }) async {
    final res = await _post('/bikes/list', {
      'bikeId': bikeId,
      'station': station,
      'imagePath': imagePath ?? '',
    });
    return res != null;
  }

  // Owner rental history
  Future<List<BikeRentalRecord>> fetchRentalHistory(String userId) async {
    final data = await _get('/owner/rentals/$userId');
    if (data == null) return BikeRentalRecord.sampleRecords();
    try {
      return (data as List).map((e) => BikeRentalRecord.fromJson(e)).toList();
    } catch (_) {
      return BikeRentalRecord.sampleRecords();
    }
  }

  // Payment
  Future<Map<String, dynamic>?> createOrder(double amount) async {
    final res = await _post('/create-order', {'amount': amount});
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<bool> verifyPayment(Map<String, dynamic> data) async {
    final res = await _post('/verify-payment', data);
    if (res == null) return false;
    return res['success'] == true;
  }

  Future<bool> payWithWallet({
    required String rideId,
    required double amount,
  }) async {
    final res = await _post('/wallet/pay', {'rideId': rideId, 'amount': amount});
    if (res == null) return true;
    return res['success'] == true;
  }

  Future<double> getWalletBalance() async {
    final res = await _get('/wallet/balance');
    if (res == null) return 120.0;
    return (res['balance'] as num).toDouble();
  }

  Future<bool> processPayment({
    required String rideId,
    required double amount,
    required String method,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }
}
