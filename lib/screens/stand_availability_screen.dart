import 'package:flutter/material.dart';
import '../models/bike_state.dart';
import '../models/bike.dart';
import '../services/api_service.dart';
import 'bike_details_screen.dart';

class StandAvailabilityScreen extends StatefulWidget {
  const StandAvailabilityScreen({super.key});

  @override
  State<StandAvailabilityScreen> createState() =>
      _StandAvailabilityScreenState();
}

class _StandAvailabilityScreenState extends State<StandAvailabilityScreen> {
  late Future<List<StandAvailability>> _standsFuture;

  @override
  void initState() {
    super.initState();
    _standsFuture = ApiService().fetchStands();
  }

  void _refresh() {
    setState(() {
      _standsFuture = ApiService().fetchStands();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('Campus Stands'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
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
          final totalAvailable =
              stands.fold(0, (sum, s) => sum + s.availableBikes);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: const Color(0xFF2E7D32),
            child: CustomScrollView(
              slivers: [
                // Summary banner
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          icon: Icons.pedal_bike_rounded,
                          value: '$totalAvailable',
                          label: 'Bikes Available',
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _SummaryItem(
                          icon: Icons.location_on_rounded,
                          value: '${stands.length}',
                          label: 'Total Stands',
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _SummaryItem(
                          icon: Icons.check_circle_rounded,
                          value:
                              '${stands.where((s) => s.availableBikes > 0).length}',
                          label: 'Active Stands',
                        ),
                      ],
                    ),
                  ),
                ),
                // Info box
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF90CAF9)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Color(0xFF1565C0), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Walk to a nearby stand and scan the QR on any available bike to start your ride.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF1565C0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Section header
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'All Stands',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B5E20)),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                // Stand list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _StandCard(
                      stand: stands[i],
                      onTap: () => _showStandDetail(context, stands[i]),
                    ),
                    childCount: stands.length,
                  ),
                ),
                // Campus map image placeholder
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campus Stand Locations',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                // Static campus map placeholder
                                CustomPaint(
                                  size: const Size(double.infinity, 200),
                                  painter: _StaticCampusMap(),
                                ),
                                // Stand dots
                                ..._buildStandDots(stands),
                                // Legend
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _LegendDot(
                                            color: Color(0xFF2E7D32),
                                            label: 'Has bikes'),
                                        SizedBox(height: 4),
                                        _LegendDot(
                                            color: Color(0xFFD32F2F),
                                            label: 'Empty'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Static campus map — stands are at fixed locations',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildStandDots(List<StandAvailability> stands) {
    final positions = [
      [0.25, 0.3],
      [0.45, 0.55],
      [0.7, 0.2],
      [0.2, 0.7],
      [0.8, 0.75],
      [0.55, 0.85],
    ];
    return List.generate(stands.length, (i) {
      final stand = stands[i];
      final pos = positions[i];
      return LayoutBuilder(builder: (ctx, constraints) {
        return Positioned(
          left: pos[0] * constraints.maxWidth - 12,
          top: pos[1] * 200 - 12,
          child: GestureDetector(
            onTap: () => _showStandDetail(context, stand),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: stand.availableBikes > 0
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFD32F2F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (stand.availableBikes > 0
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD32F2F))
                        .withOpacity(0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${stand.availableBikes}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        );
      });
    });
  }

  void _showStandDetail(BuildContext context, StandAvailability stand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stand.availableBikes > 0
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on_rounded,
                      color: stand.availableBikes > 0
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD32F2F),
                      size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stand.standName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20))),
                      Text(stand.description,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _InfoPill(
                  label: '${stand.availableBikes} available',
                  color: stand.availableBikes > 0
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD32F2F),
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  label: '${stand.totalSlots} total slots',
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (stand.availableBikes > 0) ...[
              const Text('Available Bikes',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                      fontSize: 15)),
              const SizedBox(height: 12),
              ...stand.availableBikeIds.map((bikeId) => _BikeTile(
                    bikeId: bikeId,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BikeDetailsScreen(
                            bike: Bike(
                              id: bikeId,
                              station: stand.standName,
                              isAvailable: true,
                              batteryLevel: 75,
                              pricePerHour: 10.0,
                            ),
                          ),
                        ),
                      );
                    },
                  )),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFFD32F2F), size: 20),
                    SizedBox(width: 10),
                    Text('No bikes available at this stand.',
                        style: TextStyle(color: Color(0xFFD32F2F))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StaticCampusMap extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final buildingPaint = Paint()..color = const Color(0xFFC8E6C9);

    canvas.drawLine(Offset(0, size.height * 0.45),
        Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.45, 0),
        Offset(size.width * 0.45, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width * 0.7, size.height * 0.25), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width * 0.6, size.height * 0.7), roadPaint);

    final buildings = [
      const Rect.fromLTWH(10, 10, 80, 50),
      const Rect.fromLTWH(120, 60, 60, 40),
      const Rect.fromLTWH(200, 10, 70, 45),
      const Rect.fromLTWH(60, 100, 90, 55),
      const Rect.fromLTWH(180, 100, 65, 50),
      const Rect.fromLTWH(20, 140, 55, 40),
    ];
    for (final r in buildings) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)), buildingPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _StandCard extends StatelessWidget {
  final StandAvailability stand;
  final VoidCallback onTap;

  const _StandCard({required this.stand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAvailable = stand.availableBikes > 0;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasAvailable
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${stand.availableBikes}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: hasAvailable
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stand.standName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stand.description,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasAvailable
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasAvailable
                                ? '${stand.availableBikes} cycles available'
                                : 'No cycles available',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasAvailable
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFD32F2F),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stand.totalSlots} slots total',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryItem(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
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

class _BikeTile extends StatelessWidget {
  final String bikeId;
  final VoidCallback onTap;

  const _BikeTile({required this.bikeId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Row(
          children: [
            const Icon(Icons.electric_bike_rounded,
                color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 10),
            Text(bikeId,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20))),
            const Spacer(),
            const Text('Tap to book',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
