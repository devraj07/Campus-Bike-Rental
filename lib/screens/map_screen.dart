import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bike_state.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<StandAvailability>> _standsFuture;

  // Map positions are a display-layer concern — not stored in the backend.
  // Keyed by standName to remain stable even if API order changes.
  static const Map<String, List<double>> _positionMap = {
    'Academic Block A': [0.25, 0.30],
    'Library Gate':     [0.45, 0.55],
    'Hostel 1 Stand':   [0.70, 0.20],
    'Mess Block':       [0.20, 0.70],
    'Sports Complex':   [0.80, 0.75],
    'Admin Building':   [0.55, 0.85],
  };

  @override
  void initState() {
    super.initState();
    _standsFuture = ApiService().fetchStands();
  }

  void _showStationSheet(BuildContext context, StandAvailability stand) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stand.standName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stand.description,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(
                  label: '${stand.availableBikes} bikes available',
                  color: stand.availableBikes > 0
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD32F2F),
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  label: '${stand.totalSlots} slots',
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.directions_bike_rounded),
              label: const Text('Navigate Here'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('Campus Map'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {},
            tooltip: 'My Location',
          ),
        ],
      ),
      body: FutureBuilder<List<StandAvailability>>(
        future: _standsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load stands: ${snapshot.error}'),
            );
          }

          final stands = snapshot.data!;

          return Column(
            children: [
              // Legend
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    _LegendItem(
                        color: const Color(0xFF2E7D32), label: 'Available'),
                    const SizedBox(width: 16),
                    _LegendItem(
                        color: const Color(0xFFD32F2F), label: 'Full'),
                    const SizedBox(width: 16),
                    _LegendItem(
                        color: const Color(0xFF1565C0), label: 'You'),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Map background
                        Container(
                          color: const Color(0xFFE8F5E9),
                          child: CustomPaint(
                            size: Size(
                                constraints.maxWidth, constraints.maxHeight),
                            painter: _CampusMapPainter(),
                          ),
                        ),
                        // Dynamic stand markers
                        ...stands.map((stand) {
                          final pos = _positionMap[stand.standName] ??
                              [0.5, 0.5];
                          return Positioned(
                            left: pos[0] * constraints.maxWidth - 20,
                            top: pos[1] * constraints.maxHeight - 20,
                            child: GestureDetector(
                              onTap: () =>
                                  _showStationSheet(context, stand),
                              child: _StationMarker(stand: stand),
                            ),
                          );
                        }),
                        // User location dot
                        Positioned(
                          left: 0.42 * constraints.maxWidth - 10,
                          top: 0.48 * constraints.maxHeight - 10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26, blurRadius: 4)
                              ],
                            ),
                          ),
                        ),
                        // IITGN label
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 6)
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school_rounded,
                                    color: Color(0xFF2E7D32), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'IIT Gandhinagar Campus',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Bottom stand list
              Container(
                height: 130,
                color: Colors.white,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  itemCount: stands.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => _StationChip(stand: stands[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final buildingPaint = Paint()..color = const Color(0xFFC8E6C9);

    final roads = [
      [Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45)],
      [Offset(size.width * 0.45, 0), Offset(size.width * 0.45, size.height)],
      [
        Offset(0, size.height * 0.25),
        Offset(size.width * 0.7, size.height * 0.25)
      ],
      [
        Offset(size.width * 0.7, size.height * 0.25),
        Offset(size.width, size.height * 0.6)
      ],
      [
        Offset(0, size.height * 0.7),
        Offset(size.width * 0.5, size.height * 0.7)
      ],
      [
        Offset(size.width * 0.5, size.height * 0.7),
        Offset(size.width, size.height * 0.85)
      ],
    ];

    for (final r in roads) {
      canvas.drawLine(r[0], r[1], roadPaint);
    }

    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * (size.width - 60) + 10;
      final y = rng.nextDouble() * (size.height - 50) + 10;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 40 + rng.nextDouble() * 30,
              30 + rng.nextDouble() * 20),
          const Radius.circular(4),
        ),
        buildingPaint,
      );
    }

    final grassPaint =
        Paint()..color = const Color(0xFFA5D6A7).withOpacity(0.5);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.45),
            width: 80,
            height: 60),
        grassPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _StationMarker extends StatelessWidget {
  final StandAvailability stand;
  const _StationMarker({required this.stand});

  @override
  Widget build(BuildContext context) {
    final hasAvailable = stand.availableBikes > 0;
    final markerColor = hasAvailable
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: markerColor.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '${stand.availableBikes}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Icon(Icons.arrow_drop_down_rounded, color: markerColor, size: 16),
      ],
    );
  }
}

class _StationChip extends StatelessWidget {
  final StandAvailability stand;
  const _StationChip({required this.stand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Color(0xFF2E7D32), size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  stand.standName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stand.description,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${stand.availableBikes} bikes available',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: stand.availableBikes > 0
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
