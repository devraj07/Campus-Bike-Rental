import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seeds Firestore with realistic sample data for IITGN Campus Bike Rental.
///
/// Run this once from a debug screen or temporarily from main().
/// Collections seeded: users, bikes, stands, rides, rental_records.
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stable IDs so cross-collection references stay consistent ──────────────

  static const _users = {
    'rahul': 'user_rahul_sharma',
    'priya': 'user_priya_patel',
    'arjun': 'user_arjun_singh',
    'sneha': 'user_sneha_gupta',
    'vikram': 'user_vikram_nair',
  };

  static const _bikes = {
    'b01': 'bike_001',
    'b02': 'bike_002',
    'b03': 'bike_003',
    'b04': 'bike_004',
    'b05': 'bike_005',
    'b06': 'bike_006',
  };

  static const _stands = {
    'academic': 'stand_academic_block',
    'library': 'stand_library_gate',
    'hostel1': 'stand_hostel1',
    'mess': 'stand_mess_block',
    'sports': 'stand_sports_complex',
    'admin': 'stand_admin_building',
  };

  // ── Public entry point ─────────────────────────────────────────────────────

  /// Seeds all collections. Safe to call multiple times — uses set() with merge:false
  /// on fixed doc IDs so duplicates overwrite rather than accumulate.
  Future<void> seedAll() async {
    debugPrint('[SeedService] Starting seed...');
    await _seedUsers();
    await _seedStands();
    await _seedBikes();
    await _seedRides();
    await _seedRentalRecords();
    debugPrint('[SeedService] Done.');
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> _seedUsers() async {
    final col = _db.collection('users');
    final batch = _db.batch();

    // Owners
    batch.set(col.doc(_users['rahul']), {
      'name': 'Rahul Sharma',
      'email': 'rahul.sharma@iitgn.ac.in',
      'totalRides': 0,
      'totalSpent': 0.0,
      'co2SavedGrams': 0.0,
      'walletBalance': 500.0,
      'role': 'owner',
    });

    batch.set(col.doc(_users['priya']), {
      'name': 'Priya Patel',
      'email': 'priya.patel@iitgn.ac.in',
      'totalRides': 0,
      'totalSpent': 0.0,
      'co2SavedGrams': 0.0,
      'walletBalance': 250.0,
      'role': 'owner',
    });

    // Renters
    batch.set(col.doc(_users['arjun']), {
      'name': 'Arjun Singh',
      'email': 'arjun.singh@iitgn.ac.in',
      'totalRides': 5,
      'totalSpent': 120.0,
      'co2SavedGrams': 4800.0,
      'walletBalance': 180.0,
      'role': 'renter',
    });

    batch.set(col.doc(_users['sneha']), {
      'name': 'Sneha Gupta',
      'email': 'sneha.gupta@iitgn.ac.in',
      'totalRides': 3,
      'totalSpent': 65.0,
      'co2SavedGrams': 2600.0,
      'walletBalance': 335.0,
      'role': 'renter',
    });

    batch.set(col.doc(_users['vikram']), {
      'name': 'Vikram Nair',
      'email': 'vikram.nair@iitgn.ac.in',
      'totalRides': 8,
      'totalSpent': 200.0,
      'co2SavedGrams': 8000.0,
      'walletBalance': 50.0,
      'role': 'renter',
    });

    await batch.commit();
    debugPrint('[SeedService] ✓ Users seeded (5)');
  }

  // ── Stands ─────────────────────────────────────────────────────────────────
  // Stand names must match MapScreen._positionMap keys exactly.

  Future<void> _seedStands() async {
    final col = _db.collection('stands');
    final batch = _db.batch();

    batch.set(col.doc(_stands['academic']), {
      'standName': 'Academic Block A',
      'description': 'Near AB-1 entrance, covered parking for 10 bikes.',
      'totalSlots': 10,
      'availableBikes': 2,
      'availableBikeIds': [_bikes['b01'], _bikes['b02']],
    });

    batch.set(col.doc(_stands['library']), {
      'standName': 'Library Gate',
      'description': 'Outside the Central Library, 8-slot stand.',
      'totalSlots': 8,
      'availableBikes': 1,
      'availableBikeIds': [_bikes['b03']],
    });

    batch.set(col.doc(_stands['hostel1']), {
      'standName': 'Hostel 1 Stand',
      'description': 'Between Hostels 1 and 2, open 24 hours.',
      'totalSlots': 6,
      'availableBikes': 1,
      'availableBikeIds': [_bikes['b04']],
    });

    batch.set(col.doc(_stands['mess']), {
      'standName': 'Mess Block',
      'description': 'Adjacent to the student mess, 8-slot stand.',
      'totalSlots': 8,
      'availableBikes': 0,
      'availableBikeIds': [],
    });

    batch.set(col.doc(_stands['sports']), {
      'standName': 'Sports Complex',
      'description': 'Near the main sports ground entrance.',
      'totalSlots': 12,
      'availableBikes': 1,
      'availableBikeIds': [_bikes['b05']],
    });

    batch.set(col.doc(_stands['admin']), {
      'standName': 'Admin Building',
      'description': 'Main administrative block, visitor-friendly.',
      'totalSlots': 6,
      'availableBikes': 0,
      'availableBikeIds': [],
    });

    await batch.commit();
    debugPrint('[SeedService] ✓ Stands seeded (6)');
  }

  // ── Bikes ──────────────────────────────────────────────────────────────────

  Future<void> _seedBikes() async {
    final col = _db.collection('bikes');
    final batch = _db.batch();

    // Owned by Rahul
    batch.set(col.doc(_bikes['b01']), {
      'station': 'Academic Block A',
      'isAvailable': true,
      'batteryLevel': 88,
      'pricePerHour': 10.0,
      'type': 'Electric',
      'distanceKm': 1.2,
      'imageUrl': '',
      'ownerId': _users['rahul'],
      'listedAt': Timestamp.fromDate(DateTime(2025, 11, 1)),
    });

    batch.set(col.doc(_bikes['b02']), {
      'station': 'Academic Block A',
      'isAvailable': true,
      'batteryLevel': 65,
      'pricePerHour': 8.0,
      'type': 'Standard',
      'distanceKm': 0.8,
      'imageUrl': '',
      'ownerId': _users['rahul'],
      'listedAt': Timestamp.fromDate(DateTime(2025, 11, 5)),
    });

    batch.set(col.doc(_bikes['b04']), {
      'station': 'Hostel 1 Stand',
      'isAvailable': true,
      'batteryLevel': 45,
      'pricePerHour': 8.0,
      'type': 'Standard',
      'distanceKm': 2.1,
      'imageUrl': '',
      'ownerId': _users['rahul'],
      'listedAt': Timestamp.fromDate(DateTime(2025, 11, 10)),
    });

    batch.set(col.doc(_bikes['b06']), {
      'station': 'Admin Building',
      'isAvailable': false, // currently on an active ride
      'batteryLevel': 72,
      'pricePerHour': 10.0,
      'type': 'Electric',
      'distanceKm': 0.5,
      'imageUrl': '',
      'ownerId': _users['rahul'],
      'listedAt': Timestamp.fromDate(DateTime(2025, 11, 15)),
    });

    // Owned by Priya
    batch.set(col.doc(_bikes['b03']), {
      'station': 'Library Gate',
      'isAvailable': true,
      'batteryLevel': 91,
      'pricePerHour': 10.0,
      'type': 'Electric',
      'distanceKm': 0.3,
      'imageUrl': '',
      'ownerId': _users['priya'],
      'listedAt': Timestamp.fromDate(DateTime(2025, 11, 3)),
    });

    batch.set(col.doc(_bikes['b05']), {
      'station': 'Sports Complex',
      'isAvailable': true,
      'batteryLevel': 55,
      'pricePerHour': 10.0,
      'type': 'Electric',
      'distanceKm': 1.7,
      'imageUrl': '',
      'ownerId': _users['priya'],
      'listedAt': Timestamp.fromDate(DateTime(2025, 11, 8)),
    });

    await batch.commit();
    debugPrint('[SeedService] ✓ Bikes seeded (6)');
  }

  // ── Rides ──────────────────────────────────────────────────────────────────

  Future<void> _seedRides() async {
    final col = _db.collection('rides');
    final batch = _db.batch();

    // Arjun – 5 completed rides
    batch.set(col.doc('ride_arjun_001'), {
      'bikeId': _bikes['b01'],
      'userId': _users['arjun'],
      'startTime': Timestamp.fromDate(DateTime(2026, 1, 5, 9, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 1, 5, 9, 45)),
      'distanceKm': 2.4,
      'cost': 8.0,
      'status': 'completed',
      'fromStation': 'Academic Block A',
      'toStation': 'Sports Complex',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_arjun_002'), {
      'bikeId': _bikes['b03'],
      'userId': _users['arjun'],
      'startTime': Timestamp.fromDate(DateTime(2026, 1, 12, 17, 30)),
      'endTime': Timestamp.fromDate(DateTime(2026, 1, 12, 18, 0)),
      'distanceKm': 1.8,
      'cost': 5.0,
      'status': 'completed',
      'fromStation': 'Library Gate',
      'toStation': 'Hostel 1 Stand',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_arjun_003'), {
      'bikeId': _bikes['b02'],
      'userId': _users['arjun'],
      'startTime': Timestamp.fromDate(DateTime(2026, 2, 3, 8, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 2, 3, 8, 30)),
      'distanceKm': 1.1,
      'cost': 4.0,
      'status': 'completed',
      'fromStation': 'Academic Block A',
      'toStation': 'Mess Block',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_arjun_004'), {
      'bikeId': _bikes['b05'],
      'userId': _users['arjun'],
      'startTime': Timestamp.fromDate(DateTime(2026, 2, 20, 15, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 2, 20, 16, 30)),
      'distanceKm': 5.2,
      'cost': 15.0,
      'status': 'completed',
      'fromStation': 'Sports Complex',
      'toStation': 'Admin Building',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_arjun_005'), {
      'bikeId': _bikes['b04'],
      'userId': _users['arjun'],
      'startTime': Timestamp.fromDate(DateTime(2026, 3, 10, 7, 45)),
      'endTime': Timestamp.fromDate(DateTime(2026, 3, 10, 8, 30)),
      'distanceKm': 2.9,
      'cost': 7.0,
      'status': 'completed',
      'fromStation': 'Hostel 1 Stand',
      'toStation': 'Academic Block A',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    // Sneha – 3 completed rides
    batch.set(col.doc('ride_sneha_001'), {
      'bikeId': _bikes['b01'],
      'userId': _users['sneha'],
      'startTime': Timestamp.fromDate(DateTime(2026, 1, 15, 11, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 1, 15, 11, 40)),
      'distanceKm': 2.0,
      'cost': 7.0,
      'status': 'completed',
      'fromStation': 'Academic Block A',
      'toStation': 'Library Gate',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_sneha_002'), {
      'bikeId': _bikes['b05'],
      'userId': _users['sneha'],
      'startTime': Timestamp.fromDate(DateTime(2026, 2, 8, 14, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 2, 8, 14, 30)),
      'distanceKm': 1.5,
      'cost': 5.0,
      'status': 'completed',
      'fromStation': 'Sports Complex',
      'toStation': 'Mess Block',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_sneha_003'), {
      'bikeId': _bikes['b03'],
      'userId': _users['sneha'],
      'startTime': Timestamp.fromDate(DateTime(2026, 3, 2, 18, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 3, 2, 18, 32)),
      'distanceKm': 1.9,
      'cost': 5.5,
      'status': 'completed',
      'fromStation': 'Library Gate',
      'toStation': 'Hostel 1 Stand',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    // Vikram – 8 completed rides
    batch.set(col.doc('ride_vikram_001'), {
      'bikeId': _bikes['b02'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2025, 12, 10, 8, 0)),
      'endTime': Timestamp.fromDate(DateTime(2025, 12, 10, 9, 0)),
      'distanceKm': 3.5,
      'cost': 8.0,
      'status': 'completed',
      'fromStation': 'Academic Block A',
      'toStation': 'Sports Complex',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_vikram_002'), {
      'bikeId': _bikes['b04'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2025, 12, 18, 17, 0)),
      'endTime': Timestamp.fromDate(DateTime(2025, 12, 18, 17, 45)),
      'distanceKm': 2.8,
      'cost': 7.5,
      'status': 'completed',
      'fromStation': 'Hostel 1 Stand',
      'toStation': 'Mess Block',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_vikram_003'), {
      'bikeId': _bikes['b01'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2026, 1, 3, 9, 30)),
      'endTime': Timestamp.fromDate(DateTime(2026, 1, 3, 10, 15)),
      'distanceKm': 3.0,
      'cost': 7.5,
      'status': 'completed',
      'fromStation': 'Academic Block A',
      'toStation': 'Library Gate',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_vikram_004'), {
      'bikeId': _bikes['b03'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2026, 1, 20, 16, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 1, 20, 17, 10)),
      'distanceKm': 4.1,
      'cost': 12.0,
      'status': 'completed',
      'fromStation': 'Library Gate',
      'toStation': 'Admin Building',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_vikram_005'), {
      'bikeId': _bikes['b05'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2026, 2, 1, 7, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 2, 1, 8, 0)),
      'distanceKm': 3.8,
      'cost': 10.0,
      'status': 'completed',
      'fromStation': 'Sports Complex',
      'toStation': 'Academic Block A',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_vikram_006'), {
      'bikeId': _bikes['b02'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2026, 2, 14, 12, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 2, 14, 12, 45)),
      'distanceKm': 2.5,
      'cost': 7.5,
      'status': 'completed',
      'fromStation': 'Academic Block A',
      'toStation': 'Hostel 1 Stand',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_vikram_007'), {
      'bikeId': _bikes['b04'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2026, 3, 5, 18, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 3, 5, 18, 30)),
      'distanceKm': 1.6,
      'cost': 5.0,
      'status': 'completed',
      'fromStation': 'Hostel 1 Stand',
      'toStation': 'Mess Block',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    batch.set(col.doc('ride_vikram_008'), {
      'bikeId': _bikes['b01'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(DateTime(2026, 3, 28, 9, 0)),
      'endTime': Timestamp.fromDate(DateTime(2026, 3, 28, 10, 0)),
      'distanceKm': 3.2,
      'cost': 10.0,
      'status': 'completed',
      'fromStation': 'Academic Block A',
      'toStation': 'Sports Complex',
      'paymentMethod': 'wallet',
      'paymentStatus': 'paid',
    });

    // Active ride – Vikram currently riding bike_006
    batch.set(col.doc('ride_vikram_active'), {
      'bikeId': _bikes['b06'],
      'userId': _users['vikram'],
      'startTime': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 22)),
      ),
      'endTime': null,
      'distanceKm': 0.0,
      'cost': 0.0,
      'status': 'active',
      'fromStation': 'Admin Building',
      'toStation': '',
    });

    await batch.commit();
    debugPrint('[SeedService] ✓ Rides seeded (17 total, 1 active)');
  }

  // ── Rental Records (owner view) ────────────────────────────────────────────

  Future<void> _seedRentalRecords() async {
    final col = _db.collection('rental_records');
    final batch = _db.batch();

    // Records for Rahul's bikes (b01, b02, b04, b06)
    batch.set(col.doc('rr_001'), {
      'bikeId': _bikes['b01'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Arjun Singh',
      'date': Timestamp.fromDate(DateTime(2026, 1, 5, 9, 0)),
      'durationMinutes': 45,
      'earnings': 8.0,
    });

    batch.set(col.doc('rr_002'), {
      'bikeId': _bikes['b01'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Sneha Gupta',
      'date': Timestamp.fromDate(DateTime(2026, 1, 15, 11, 0)),
      'durationMinutes': 40,
      'earnings': 7.0,
    });

    batch.set(col.doc('rr_003'), {
      'bikeId': _bikes['b01'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2026, 1, 3, 9, 30)),
      'durationMinutes': 45,
      'earnings': 7.5,
    });

    batch.set(col.doc('rr_004'), {
      'bikeId': _bikes['b01'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2026, 3, 28, 9, 0)),
      'durationMinutes': 60,
      'earnings': 10.0,
    });

    batch.set(col.doc('rr_005'), {
      'bikeId': _bikes['b02'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Arjun Singh',
      'date': Timestamp.fromDate(DateTime(2026, 2, 3, 8, 0)),
      'durationMinutes': 30,
      'earnings': 4.0,
    });

    batch.set(col.doc('rr_006'), {
      'bikeId': _bikes['b02'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2025, 12, 10, 8, 0)),
      'durationMinutes': 60,
      'earnings': 8.0,
    });

    batch.set(col.doc('rr_007'), {
      'bikeId': _bikes['b02'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2026, 2, 14, 12, 0)),
      'durationMinutes': 45,
      'earnings': 7.5,
    });

    batch.set(col.doc('rr_008'), {
      'bikeId': _bikes['b04'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Arjun Singh',
      'date': Timestamp.fromDate(DateTime(2026, 3, 10, 7, 45)),
      'durationMinutes': 45,
      'earnings': 7.0,
    });

    batch.set(col.doc('rr_009'), {
      'bikeId': _bikes['b04'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2025, 12, 18, 17, 0)),
      'durationMinutes': 45,
      'earnings': 7.5,
    });

    batch.set(col.doc('rr_010'), {
      'bikeId': _bikes['b04'],
      'ownerId': _users['rahul'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2026, 3, 5, 18, 0)),
      'durationMinutes': 30,
      'earnings': 5.0,
    });

    // Records for Priya's bikes (b03, b05)
    batch.set(col.doc('rr_011'), {
      'bikeId': _bikes['b03'],
      'ownerId': _users['priya'],
      'rentedBy': 'Arjun Singh',
      'date': Timestamp.fromDate(DateTime(2026, 1, 12, 17, 30)),
      'durationMinutes': 30,
      'earnings': 5.0,
    });

    batch.set(col.doc('rr_012'), {
      'bikeId': _bikes['b03'],
      'ownerId': _users['priya'],
      'rentedBy': 'Sneha Gupta',
      'date': Timestamp.fromDate(DateTime(2026, 3, 2, 18, 0)),
      'durationMinutes': 32,
      'earnings': 5.5,
    });

    batch.set(col.doc('rr_013'), {
      'bikeId': _bikes['b03'],
      'ownerId': _users['priya'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2026, 1, 20, 16, 0)),
      'durationMinutes': 70,
      'earnings': 12.0,
    });

    batch.set(col.doc('rr_014'), {
      'bikeId': _bikes['b05'],
      'ownerId': _users['priya'],
      'rentedBy': 'Arjun Singh',
      'date': Timestamp.fromDate(DateTime(2026, 2, 20, 15, 0)),
      'durationMinutes': 90,
      'earnings': 15.0,
    });

    batch.set(col.doc('rr_015'), {
      'bikeId': _bikes['b05'],
      'ownerId': _users['priya'],
      'rentedBy': 'Sneha Gupta',
      'date': Timestamp.fromDate(DateTime(2026, 2, 8, 14, 0)),
      'durationMinutes': 30,
      'earnings': 5.0,
    });

    batch.set(col.doc('rr_016'), {
      'bikeId': _bikes['b05'],
      'ownerId': _users['priya'],
      'rentedBy': 'Vikram Nair',
      'date': Timestamp.fromDate(DateTime(2026, 2, 1, 7, 0)),
      'durationMinutes': 60,
      'earnings': 10.0,
    });

    await batch.commit();
    debugPrint('[SeedService] ✓ Rental records seeded (16)');
  }
}
