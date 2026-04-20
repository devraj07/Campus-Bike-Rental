import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/bike.dart';
import '../models/ride.dart';
import '../models/bike_state.dart';
import '../models/bike_rental_record.dart';
import 'user_session.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
        renterName: d['renterName'] as String? ?? '',
        paymentStatus: d['paymentStatus'] as String? ?? '',
      );
    }).toList();
  }

  // ─── Bike Rides (owner view) ──────────────────────────────────────────────

  Future<List<Ride>> fetchBikeRides(String bikeId) async {
    final snapshot = await _db
        .collection('rides')
        .where('bikeId', isEqualTo: bikeId)
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
        distanceKm: (d['distanceKm'] as num?)?.toDouble() ?? 0.0,
        cost: (d['cost'] as num?)?.toDouble() ?? 0.0,
        status: d['status'] as String? ?? 'active',
        fromStation: d['fromStation'] as String? ?? '',
        toStation: d['toStation'] as String? ?? '',
        renterName: d['renterName'] as String? ?? '',
        paymentStatus: d['paymentStatus'] as String? ?? '',
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

  // ─── Push OTP to lock (ESP32 reads this from Firestore) ──────────────────

  Future<void> pushOtpToLock(String bikeId, String otp) async {
    await _db.collection('bikes').doc(bikeId).update({
      'currentOtp': otp,
      'lockStatus': 'locked', // reset status so any stale 'unlocked' is cleared
    });
  }

  // ─── Start Rental ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startRental(String bikeId, String pin) async {
    final rideRef = _db.collection('rides').doc();
    final now = DateTime.now();

    // Fetch bike to get current station and price
    final bikeDoc = await _db.collection('bikes').doc(bikeId).get();
    final bikeData = bikeDoc.data() ?? {};
    final fromStation = bikeData['station'] as String? ?? '';
    final pricePerHour = (bikeData['pricePerHour'] as num?)?.toDouble() ?? 10.0;

    final batch = _db.batch();

    batch.set(rideRef, {
      'bikeId': bikeId,
      'userId': UserSession.userId,
      'renterName': UserSession.name,
      'pin': pin,
      'startTime': Timestamp.fromDate(now),
      'endTime': null,
      'distanceKm': 0.0,
      'cost': 0.0,
      'status': 'active',
      'fromStation': fromStation,
      'toStation': '',
      'pricePerHour': pricePerHour,
    });

    // Mark bike unavailable + clear OTP + set lockStatus to on_ride
    batch.update(_db.collection('bikes').doc(bikeId), {
      'isAvailable': false,
      'currentOtp': FieldValue.delete(), // OTP consumed
      'lockStatus': 'on_ride',           // signals ESP32 ride is active
    });

    // Record active ride on user doc for session restore after app restart
    batch.update(_db.collection('users').doc(UserSession.userId), {
      'activeRideId': rideRef.id,
    });

    // Remove bike from its stand's available list
    final standSnap = await _db
        .collection('stands')
        .where('availableBikeIds', arrayContains: bikeId)
        .limit(1)
        .get();
    if (standSnap.docs.isNotEmpty) {
      batch.update(standSnap.docs.first.reference, {
        'availableBikes': FieldValue.increment(-1),
        'availableBikeIds': FieldValue.arrayRemove([bikeId]),
      });
    }

    await batch.commit();

    return {
      'rideId': rideRef.id,
      'pin': pin,
      'startTime': now.toIso8601String(),
    };
  }

  // ─── End Ride ─────────────────────────────────────────────────────────────

  /// Signal the ESP32 to lock the bike and start sending ride duration.
  Future<void> signalEndRide(String bikeId) async {
    await _db.collection('bikes').doc(bikeId).update({
      'lockStatus': 'end_requested',
    });
  }

  Future<Map<String, dynamic>> endRide(
    String rideId, {
    String? toStation,
    int? hardwareDurationSeconds, // provided by ESP32 via Firestore
  }) async {
    final now = DateTime.now();
    final rideRef = _db.collection('rides').doc(rideId);
    final rideDoc = await rideRef.get();
    final data = rideDoc.data()!;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final bikeId = data['bikeId'] as String;

    final pricePerHour = (data['pricePerHour'] as num?)?.toDouble() ?? 10.0;
    // Prefer hardware-reported duration; fall back to client-side calculation.
    final durationMinutes = hardwareDurationSeconds != null
        ? hardwareDurationSeconds ~/ 60
        : now.difference(startTime).inMinutes;
    final distanceKm = durationMinutes * 0.03;
    final cost = double.parse(
        (durationMinutes / 60 * pricePerHour).toStringAsFixed(2));

    final batch = _db.batch();

    batch.update(rideRef, {
      'endTime': Timestamp.fromDate(now),
      'cost': cost,
      'distanceKm': distanceKm,
      'status': 'completed',
      if (toStation != null && toStation.isNotEmpty) 'toStation': toStation,
    });

    // Mark bike available again + signal ESP32 to re-lock
    batch.update(_db.collection('bikes').doc(bikeId), {
      'isAvailable': true,
      'lockStatus': 'locked', // tells ESP32 the ride is over, re-lock
      if (toStation != null && toStation.isNotEmpty) 'station': toStation,
    });

    // Clear active ride from user doc
    batch.update(_db.collection('users').doc(UserSession.userId), {
      'activeRideId': FieldValue.delete(),
    });

    // Add bike to the drop stand's availability
    if (toStation != null && toStation.isNotEmpty) {
      final standSnap = await _db
          .collection('stands')
          .where('standName', isEqualTo: toStation)
          .limit(1)
          .get();
      if (standSnap.docs.isNotEmpty) {
        batch.update(standSnap.docs.first.reference, {
          'availableBikes': FieldValue.increment(1),
          'availableBikeIds': FieldValue.arrayUnion([bikeId]),
        });
      }
    }

    await batch.commit();

    return {
      'rideId': rideId,
      'endTime': now.toIso8601String(),
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
      'cost': cost,
    };
  }

  // ─── Payment ──────────────────────────────────────────────────────────────

  Future<bool> processPayment({
    required String rideId,
    required String bikeId,
    required double amount,
    required String method,
    String? razorpayPaymentId,
  }) async {
    final batch = _db.batch();

    // 1. Mark ride as paid
    final rideRef = _db.collection('rides').doc(rideId);
    final rideDoc = await rideRef.get();
    final rideData = rideDoc.data()!;

    batch.update(rideRef, {
      'paymentMethod': method,
      'paymentStatus': 'paid',
      'paidAt': Timestamp.now(),
      if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
    });

    // 2. Create rental record for the bike owner
    final bikeDoc = await _db.collection('bikes').doc(bikeId).get();
    final ownerId = bikeDoc.data()?['ownerId'] as String?;
    if (ownerId != null) {
      final startTime = (rideData['startTime'] as Timestamp).toDate();
      final endTime = rideData['endTime'] != null
          ? (rideData['endTime'] as Timestamp).toDate()
          : DateTime.now();
      final durationMinutes = endTime.difference(startTime).inMinutes;

      final rentalRef = _db.collection('rental_records').doc();
      batch.set(rentalRef, {
        'bikeId': bikeId,
        'ownerId': ownerId,
        'rentedBy': UserSession.name,
        'date': rideData['startTime'],
        'durationMinutes': durationMinutes,
        'earnings': double.parse((amount * 0.7).toStringAsFixed(2)),
      });
    }

    // 3. Update renter's stats
    final userRef = _db.collection('users').doc(UserSession.userId);
    batch.update(userRef, {
      'totalRides': FieldValue.increment(1),
      'totalSpent': FieldValue.increment(amount),
      if (method == 'WALLET') 'walletBalance': FieldValue.increment(-amount),
    });

    await batch.commit();

    // Keep local session in sync
    if (method == 'WALLET') {
      UserSession.walletBalance -= amount;
    }

    return true;
  }

  // ─── Fetch Single Bike ────────────────────────────────────────────────────

  Future<Bike?> fetchBikeById(String bikeId) async {
    final doc = await _db.collection('bikes').doc(bikeId).get();
    if (!doc.exists) return null;
    final d = doc.data()!;

    // Look up owner name from the users collection via ownerId
    String ownerName = '';
    final ownerId = d['ownerId'] as String?;
    if (ownerId != null) {
      final ownerDoc = await _db.collection('users').doc(ownerId).get();
      ownerName = ownerDoc.data()?['name'] as String? ?? '';
    }

    return Bike(
      id: doc.id,
      station: d['station'] as String,
      isAvailable: d['isAvailable'] as bool,
      batteryLevel: (d['batteryLevel'] as num).toInt(),
      pricePerHour: (d['pricePerHour'] as num).toDouble(),
      type: d['type'] as String? ?? 'Standard',
      distanceKm: (d['distanceKm'] as num?)?.toDouble() ?? 0.0,
      imageUrl: d['imageUrl'] as String? ?? '',
      ownerName: ownerName,
    );
  }

  // ─── Owner Bike ───────────────────────────────────────────────────────────

  Future<Bike?> fetchOwnerBike(String userId) async {
    final snapshot = await _db
        .collection('bikes')
        .where('ownerId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
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
  }

  // ─── Bike Listing ─────────────────────────────────────────────────────────

  Future<String> uploadBikeImage(String bikeId, String localPath) async {
    final ref = _storage.ref().child('bikes/$bikeId.jpg');
    await ref.putFile(File(localPath)).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException(
        'Image upload timed out.',
      ),
    );
    return await ref.getDownloadURL().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Fetching image URL timed out.',
      ),
    );
  }

  Future<bool> submitBikeListing({
    required String bikeId,
    required String station,
    required double pricePerHour,
    String? imagePath,
  }) async {
    try {
      String imageUrl = '';
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          imageUrl = await uploadBikeImage(bikeId, imagePath);
        } on FirebaseException catch (e) {
          // Continue listing without image if storage object lookup fails.
          if (e.code != 'object-not-found') rethrow;
        }
      }
      await _db.collection('bikes').doc(bikeId).set({
        'station': station,
        'isAvailable': true,
        'isListedForRent': true,
        'batteryLevel': 100,
        'pricePerHour': pricePerHour,
        'type': 'Standard',
        'distanceKm': 0.0,
        'imageUrl': imageUrl,
        'ownerId': UserSession.userId,
        'listedAt': Timestamp.now(),
      }).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException(
          'Saving bike listing timed out.',
        ),
      );
      return true;
    } on FirebaseException catch (e) {
      if (e.plugin == 'firebase_storage') {
        throw Exception('Storage error (${e.code}): ${e.message}');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Operation timed out.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // ─── Owner PIN ────────────────────────────────────────────────────────────

  Future<void> saveOwnerPin(String bikeId, String pin) async {
    await _db.collection('bikes').doc(bikeId).update({'ownerPin': pin});
  }

  // ─── Update Hourly Rate ───────────────────────────────────────────────────

  Future<void> updatePricePerHour(String bikeId, double price) async {
    await _db.collection('bikes').doc(bikeId).update({'pricePerHour': price});
  }

  // ─── Withdraw Earnings ────────────────────────────────────────────────────

  Future<void> withdrawEarnings(String userId, double amount) async {
    await _db.collection('users').doc(userId).update({
      'withdrawnEarnings': FieldValue.increment(amount),
    });
  }

  // ─── Fetch Withdrawn Earnings ─────────────────────────────────────────────

  Future<double> fetchWithdrawnEarnings(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return (doc.data()?['withdrawnEarnings'] as num?)?.toDouble() ?? 0.0;
  }

  // ─── Update Listing Status ────────────────────────────────────────────────

  Future<void> updateListingStatus(
      String bikeId, {required bool isListed}) async {
    await _db.collection('bikes').doc(bikeId).update({
      'isListedForRent': isListed,
      'isAvailable': isListed,
    });
  }

  // ─── Fetch owner bike raw data ────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchOwnerBikeData(String userId) async {
    final snapshot = await _db
        .collection('bikes')
        .where('ownerId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  // ─── Active Ride Restore ──────────────────────────────────────────────────

  /// Checks the user's Firestore doc for a stored activeRideId.
  /// Returns the ride + bike if one is still active, null otherwise.
  Future<void> ingestHardwarePayload({
    required String bikeId,
    required String topic,
    required Map<String, dynamic> payload,
  }) async {
    final now = Timestamp.now();

    final dynamic lockStatus = payload['lockStatus'];
    final dynamic batteryLevel = payload['batteryLevel'];
    final dynamic rideDurationSeconds = payload['rideDurationSeconds'];
    final dynamic rideId = payload['rideId'];
    final dynamic standName = payload['standName'];
    final dynamic currentOtp = payload['currentOtp'];

    final bikeUpdate = <String, dynamic>{
      'hardware.lastSeenAt': now,
      'hardware.lastTopic': topic,
      'hardware.lastPayload': payload,
    };

    if (lockStatus is String && lockStatus.isNotEmpty) {
      bikeUpdate['lockStatus'] = lockStatus;
    }
    if (batteryLevel is num) {
      bikeUpdate['batteryLevel'] = batteryLevel.toInt();
      bikeUpdate['hardware.batteryLevel'] = batteryLevel.toInt();
    }
    if (standName is String && standName.isNotEmpty) {
      bikeUpdate['station'] = standName;
    }
    if (currentOtp is String && currentOtp.isNotEmpty) {
      bikeUpdate['currentOtp'] = currentOtp;
    }
    if (rideDurationSeconds is num) {
      bikeUpdate['hardware.rideDurationSeconds'] = rideDurationSeconds.toInt();
    }

    await _db.collection('bikes').doc(bikeId).set(
          bikeUpdate,
          SetOptions(merge: true),
        );

    if (rideId is String && rideId.isNotEmpty && rideDurationSeconds is num) {
      await _db.collection('rides').doc(rideId).set({
        'rideDurationSeconds': rideDurationSeconds.toInt(),
        'hardwareUpdatedAt': now,
      }, SetOptions(merge: true));
    }

    await _db.collection('hardware_events').add({
      'bikeId': bikeId,
      'topic': topic,
      'payload': payload,
      'createdAt': now,
    });
  }

  Future<({String rideId, Bike bike, DateTime startTime})?> fetchActiveRide(
      String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final activeRideId = userDoc.data()?['activeRideId'] as String?;
    if (activeRideId == null) return null;

    final rideDoc = await _db.collection('rides').doc(activeRideId).get();
    if (!rideDoc.exists) return null;
    final rideData = rideDoc.data()!;
    if (rideData['status'] != 'active') return null;

    final bikeId = rideData['bikeId'] as String;
    final bikeDoc = await _db.collection('bikes').doc(bikeId).get();
    if (!bikeDoc.exists) return null;
    final d = bikeDoc.data()!;

    return (
      rideId: activeRideId,
      startTime: (rideData['startTime'] as Timestamp).toDate(),
      bike: Bike(
        id: bikeId,
        station: d['station'] as String,
        isAvailable: d['isAvailable'] as bool,
        batteryLevel: (d['batteryLevel'] as num).toInt(),
        pricePerHour: (d['pricePerHour'] as num).toDouble(),
        type: d['type'] as String? ?? 'Standard',
        distanceKm: (d['distanceKm'] as num?)?.toDouble() ?? 0.0,
        imageUrl: d['imageUrl'] as String? ?? '',
      ),
    );
  }
}
