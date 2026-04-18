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
}
