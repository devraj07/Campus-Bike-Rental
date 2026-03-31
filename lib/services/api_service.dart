import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bike.dart';
import '../models/ride.dart';
import '../models/bike_state.dart';
import '../models/bike_rental_record.dart';
import '../utils/code_generator.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Bikes ───────────────────────────────────────────────────────────────

  Future<List<Bike>> fetchAvailableBikes({String? query}) async {
    Query<Map<String, dynamic>> q = _db
        .collection('bikes')
        .where('isAvailable', isEqualTo: true);

    final snapshot = await q.get();
    final bikes = snapshot.docs.map((doc) {
      final d = doc.data();
      return Bike(
        id: doc.id,
        station: d['station'] as String,
        isAvailable: d['isAvailable'] as bool,
        batteryLevel: (d['batteryLevel'] as num).toInt(),
        pricePerHour: (d['pricePerHour'] as num).toDouble(),
        type: d['type'] as String? ?? 'Standard',
        distanceKm: (d['distanceKm'] as num?)?.toDouble() ?? 0.0,
        imageUrl: d['imageUrl'] as String? ?? '',
      );
    }).toList();

    if (query != null && query.isNotEmpty) {
      return bikes
          .where((b) =>
              b.id.toLowerCase().contains(query.toLowerCase()) ||
              b.station.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    return bikes;
  }

  // ─── Stands ──────────────────────────────────────────────────────────────

  Future<List<StandAvailability>> fetchStands() async {
    final snapshot = await _db.collection('stands').get();
    return snapshot.docs.map((doc) {
      final d = doc.data();
      return StandAvailability(
        standId: doc.id,
        standName: d['standName'] as String,
        description: d['description'] as String,
        totalSlots: (d['totalSlots'] as num).toInt(),
        availableBikes: (d['availableBikes'] as num).toInt(),
        availableBikeIds: List<String>.from(d['availableBikeIds'] ?? []),
      );
    }).toList();
  }

  // ─── User Profile ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User not found');
    final d = doc.data()!;
    return {
      'name': d['name'] as String,
      'email': d['email'] as String,
      'totalRides': (d['totalRides'] as num).toInt(),
      'totalSpent': (d['totalSpent'] as num).toDouble(),
      'co2SavedGrams': (d['co2SavedGrams'] as num).toDouble(),
      'walletBalance': (d['walletBalance'] as num).toDouble(),
    };
  }

  // ─── Ride History (renter) ────────────────────────────────────────────────

  Future<List<Ride>> fetchRideHistory(String userId) async {
    final snapshot = await _db
        .collection('rides')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final d = doc.data();
      return Ride(
        id: doc.id,
        bikeId: d['bikeId'] as String,
        startTime: (d['startTime'] as Timestamp).toDate(),
        endTime: d['endTime'] != null
            ? (d['endTime'] as Timestamp).toDate()
            : null,
        distanceKm: (d['distanceKm'] as num).toDouble(),
        cost: (d['cost'] as num).toDouble(),
        status: d['status'] as String,
        fromStation: d['fromStation'] as String,
        toStation: d['toStation'] as String? ?? '',
      );
    }).toList();
  }

  // ─── Rental History (owner) ───────────────────────────────────────────────

  Future<List<BikeRentalRecord>> fetchRentalHistory(String userId) async {
    final snapshot = await _db
        .collection('rental_records')
        .where('ownerId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final d = doc.data();
      return BikeRentalRecord(
        id: doc.id,
        bikeId: d['bikeId'] as String,
        rentedBy: d['rentedBy'] as String,
        date: (d['date'] as Timestamp).toDate(),
        duration: Duration(minutes: (d['durationMinutes'] as num).toInt()),
        earnings: (d['earnings'] as num).toDouble(),
      );
    }).toList();
  }

  // ─── Start Rental ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startRental(String bikeId, String pin) async {
    final rideRef = _db.collection('rides').doc();
    final now = DateTime.now();

    await rideRef.set({
      'bikeId': bikeId,
      'userId': 'USR-001',           // replace with FirebaseAuth.instance.currentUser!.uid once auth is live
      'pin': pin,
      'startTime': Timestamp.fromDate(now),
      'endTime': null,
      'distanceKm': 0.0,
      'cost': 0.0,
      'status': 'active',
      'fromStation': '',
      'toStation': '',
    });

    // Mark bike as unavailable
    await _db.collection('bikes').doc(bikeId).update({'isAvailable': false});

    return {
      'rideId': rideRef.id,
      'pin': pin,
      'startTime': now.toIso8601String(),
    };
  }

  // ─── End Ride ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> endRide(String rideId) async {
    final now = DateTime.now();
    final rideRef = _db.collection('rides').doc(rideId);
    final rideDoc = await rideRef.get();
    final startTime = (rideDoc.data()!['startTime'] as Timestamp).toDate();

    final durationMinutes = now.difference(startTime).inMinutes;
    final cost = (durationMinutes / 60 * 10).roundToDouble();

    await rideRef.update({
      'endTime': Timestamp.fromDate(now),
      'cost': cost,
      'status': 'completed',
    });

    final bikeId = rideDoc.data()!['bikeId'] as String;
    await _db.collection('bikes').doc(bikeId).update({'isAvailable': true});

    return {
      'rideId': rideId,
      'endTime': now.toIso8601String(),
      'durationMinutes': durationMinutes,
      'cost': cost,
    };
  }

  // ─── Payment ──────────────────────────────────────────────────────────────

  Future<bool> processPayment({
    required String rideId,
    required double amount,
    required String method,
  }) async {
    await _db.collection('rides').doc(rideId).update({
      'paymentMethod': method,
      'paymentStatus': 'paid',
      'paidAt': Timestamp.now(),
    });
    return true;
  }

  // ─── Bike Listing ─────────────────────────────────────────────────────────

  Future<bool> submitBikeListing({
    required String bikeId,
    required String station,
    String? imagePath,
  }) async {
    await _db.collection('bikes').doc(bikeId).set({
      'station': station,
      'isAvailable': true,
      'batteryLevel': 100,
      'pricePerHour': 10.0,
      'type': 'Standard',
      'distanceKm': 0.0,
      'imageUrl': imagePath ?? '',
      'ownerId': 'USR-001',         // replace with FirebaseAuth.instance.currentUser!.uid
      'listedAt': Timestamp.now(),
    });
    return true;
  }
}
