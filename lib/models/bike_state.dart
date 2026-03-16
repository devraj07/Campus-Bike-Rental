enum BikeStatus {
  docked,      // connected, no OTP
  reserved,    // connected, OTP set, waiting for rider
  unplugged,   // disconnected, no OTP entered yet
  onRide,      // OTP entered on keypad, billing started
  ownerUse,    // owner unlocked with personal PIN
}

class BikeState {
  final String bikeId;
  final BikeStatus status;
  final bool isListedForRent;
  final String? currentRenterId;
  final String? currentRenterName;
  final DateTime? reservedAt;
  final DateTime? rideStartedAt;
  final String? currentStand;
  final String? dropStand;

  const BikeState({
    required this.bikeId,
    required this.status,
    required this.isListedForRent,
    this.currentRenterId,
    this.currentRenterName,
    this.reservedAt,
    this.rideStartedAt,
    this.currentStand,
    this.dropStand,
  });

  BikeState copyWith({
    BikeStatus? status,
    bool? isListedForRent,
    String? currentRenterId,
    String? currentRenterName,
    DateTime? reservedAt,
    DateTime? rideStartedAt,
    String? currentStand,
    String? dropStand,
  }) {
    return BikeState(
      bikeId: bikeId,
      status: status ?? this.status,
      isListedForRent: isListedForRent ?? this.isListedForRent,
      currentRenterId: currentRenterId ?? this.currentRenterId,
      currentRenterName: currentRenterName ?? this.currentRenterName,
      reservedAt: reservedAt ?? this.reservedAt,
      rideStartedAt: rideStartedAt ?? this.rideStartedAt,
      currentStand: currentStand ?? this.currentStand,
      dropStand: dropStand ?? this.dropStand,
    );
  }

  String get statusLabel {
    switch (status) {
      case BikeStatus.docked:
        return 'Available';
      case BikeStatus.reserved:
        return 'Reserved';
      case BikeStatus.unplugged:
        return 'Unplugged';
      case BikeStatus.onRide:
        return 'On Ride';
      case BikeStatus.ownerUse:
        return 'Owner Use';
    }
  }
}

class StandAvailability {
  final String standId;
  final String standName;
  final String description;
  final int totalSlots;
  final int availableBikes;
  final List<String> availableBikeIds;

  const StandAvailability({
    required this.standId,
    required this.standName,
    required this.description,
    required this.totalSlots,
    required this.availableBikes,
    required this.availableBikeIds,
  });

  static List<StandAvailability> sampleStands() {
    return const [
      StandAvailability(
        standId: 'STD-001',
        standName: 'Academic Block A',
        description: 'Near main entrance, north side',
        totalSlots: 10,
        availableBikes: 4,
        availableBikeIds: ['CBR-001', 'CBR-002', 'B201', 'CBR-006'],
      ),
      StandAvailability(
        standId: 'STD-002',
        standName: 'Library Gate',
        description: 'Outside library, east entrance',
        totalSlots: 8,
        availableBikes: 0,
        availableBikeIds: [],
      ),
      StandAvailability(
        standId: 'STD-003',
        standName: 'Hostel 1 Stand',
        description: 'Between Hostel 1 and Hostel 2',
        totalSlots: 12,
        availableBikes: 3,
        availableBikeIds: ['CBR-003', 'CBR-004', 'CBR-007'],
      ),
      StandAvailability(
        standId: 'STD-004',
        standName: 'Mess Block',
        description: 'Adjacent to central mess, west side',
        totalSlots: 8,
        availableBikes: 2,
        availableBikeIds: ['CBR-005', 'CBR-008'],
      ),
      StandAvailability(
        standId: 'STD-005',
        standName: 'Sports Complex',
        description: 'Near sports complex main gate',
        totalSlots: 6,
        availableBikes: 1,
        availableBikeIds: ['CBR-009'],
      ),
      StandAvailability(
        standId: 'STD-006',
        standName: 'Admin Building',
        description: 'Ground floor, admin block',
        totalSlots: 6,
        availableBikes: 2,
        availableBikeIds: ['CBR-010', 'CBR-011'],
      ),
    ];
  }
}
