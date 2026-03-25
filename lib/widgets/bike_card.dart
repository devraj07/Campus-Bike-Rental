import 'package:flutter/material.dart';
import '../models/bike.dart';

class BikeCard extends StatelessWidget {
  final Bike bike;
  final VoidCallback? onTap;

  const BikeCard({super.key, required this.bike, this.onTap});

  Color _batteryColor(int level) {
    if (level >= 60) return const Color(0xFF2E7D32);
    if (level >= 30) return const Color(0xFFFFA000);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: bike.isAvailable ? onTap : null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Bike icon circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: bike.isAvailable
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  bike.type == 'Electric'
                      ? Icons.electric_bike_rounded
                      : Icons.directions_bike_rounded,
                  color: bike.isAvailable
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF9E9E9E),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bike.id,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                        const Spacer(),
                        _AvailabilityBadge(isAvailable: bike.isAvailable),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bike.station,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF616161),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (bike.type == 'Electric') ...[
                          Icon(Icons.battery_charging_full_rounded,
                              size: 16, color: _batteryColor(bike.batteryLevel)),
                          const SizedBox(width: 4),
                          Text(
                            '${bike.batteryLevel}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _batteryColor(bike.batteryLevel),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.currency_rupee_rounded,
                            size: 14, color: theme.colorScheme.primary),
                        Text(
                          '${bike.pricePerHour.toInt()}/hr',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.near_me_rounded,
                            size: 14, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Text(
                          '${bike.distanceKm} km',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFD32F2F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Available' : 'In Use',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAvailable
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    );
  }
}
