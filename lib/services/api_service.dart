import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bike.dart';
import '../models/ride.dart';

class ApiService {
  static const String baseUrl = 'https://api.campusbike.iitgn.ac.in';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    // Add auth token later if needed
    // 'Authorization': 'Bearer $token',
  };

  Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('GET error: $e');
      return null;
    }
  }

  Future<dynamic> _post(String endpoint, Map body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print('POST $endpoint → ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('POST error: $e');
      return null;
    }
  }

  Future<List<Bike>> fetchAvailableBikes({String? query}) async {
    final data = await _get('/bikes');

    return (data as List)
        .map((e) => Bike.fromJson(e))
        .toList();
  }

  Future<List<Ride>> fetchRideHistory(String userId) async {
    final data = await _get('/rides/$userId');

    return (data as List)
        .map((e) => Ride.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> startRide(String bikeId) async {
    return await _post('/ride/start', {'bikeId': bikeId});
  }


  Future<Map<String, dynamic>> endRide(String rideId) async {
    return await _post('/ride/end', {'rideId': rideId});
  }

  Future<Map<String, dynamic>> createOrder(double amount) async {
    return await _post('/create-order', {'amount': amount});
  }

  Future<bool> verifyPayment(Map<String, dynamic> data) async {
    final res = await _post('/verify-payment', data);
    return res['success'] == true;
  }

  Future<bool> payWithWallet({
    required String rideId,
    required double amount,
  }) async {
    final res = await _post('/wallet/pay', {
      'rideId': rideId,
      'amount': amount,
    });

    return res['success'] == true;
  }

  Future<double> getWalletBalance() async {
    final res = await _get('/wallet/balance');
    return (res['balance'] as num).toDouble();
  }
}