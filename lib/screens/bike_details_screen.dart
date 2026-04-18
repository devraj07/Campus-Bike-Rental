import 'package:flutter/material.dart';
import '../models/bike.dart';
import 'unlock_pin_screen.dart';

class BikeDetailsScreen extends StatelessWidget {
  final Bike bike;
  const BikeDetailsScreen({super.key, required this.bike});

  Widget _bikePlaceholder(Bike b) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              b.type == 'Electric'
                  ? Icons.electric_bike_rounded
                  : Icons.directions_bike_rounded,
              color: Colors.white,
              size: 72,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            b.id,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
                ),
                child: bike.imageUrl.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            bike.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _bikePlaceholder(bike),
                          ),
                          // Dark gradient overlay so the bike ID stays readable
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black54],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Text(
                              bike.id,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _bikePlaceholder(bike),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: bike.isAvailable
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: bike.isAvailable
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bike.isAvailable ? 'Available Now' : 'Currently In Use',
                          style: TextStyle(
                            color: bike.isAvailable
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFD32F2F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Details card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (bike.ownerName.isNotEmpty) ...[
                            _DetailRow(
                              icon: Icons.person_rounded,
                              label: 'Owner',
                              value: bike.ownerName,
                              iconColor: const Color(0xFF6A1B9A),
                            ),
                            const Divider(height: 28),
                          ],
                          _DetailRow(
                            icon: Icons.location_on_rounded,
                            label: 'Station',
                            value: bike.station,
                            iconColor: const Color(0xFF1565C0),
                          ),
                          const Divider(height: 28),
                          _DetailRow(
                            icon: Icons.category_rounded,
                            label: 'Type',
                            value: bike.type,
                            iconColor: const Color(0xFF7B1FA2),
                          ),
                          const Divider(height: 28),
                          _DetailRow(
                            icon: Icons.currency_rupee_rounded,
                            label: 'Rate',
                            value: '₹${bike.pricePerHour.toInt()} / hour',
                            iconColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFF2E7D32), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Helmets are available at the station. Please lock the bike after ending your ride.',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF388E3C)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (bike.isAvailable)
                    _StartRideButton(bike: bike)
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Bike Not Available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartRideButton extends StatefulWidget {
  final Bike bike;
  const _StartRideButton({required this.bike});

  @override
  State<_StartRideButton> createState() => _StartRideButtonState();
}

class _StartRideButtonState extends State<_StartRideButton> {
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UnlockPinScreen(bike: widget.bike),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _start,
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          : const Icon(Icons.play_circle_outline_rounded),
      label: Text(_loading ? 'Starting…' : 'Start Ride'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ],
    );
  }
}
