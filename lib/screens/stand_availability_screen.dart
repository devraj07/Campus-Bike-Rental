import 'package:flutter/material.dart';
import '../models/bike_state.dart';
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
    setState(() { _standsFuture = ApiService().fetchStands(); });
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
                        Container(
                            width: 1, height: 40, color: Colors.white24),
                        _SummaryItem(
                          icon: Icons.location_on_rounded,
                          value: '${stands.length}',
                          label: 'Total Stands',
                        ),
                        Container(
                            width: 1, height: 40, color: Colors.white24),
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

                // Hint row
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
                              'Tap a stand to see available bikes and start your ride.',
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

                // Expandable stand cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _StandExpansionCard(stand: stands[i]),
                      childCount: stands.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Expandable stand card ────────────────────────────────────────────────────

class _StandExpansionCard extends StatefulWidget {
  final StandAvailability stand;
  const _StandExpansionCard({required this.stand});

  @override
  State<_StandExpansionCard> createState() => _StandExpansionCardState();
}

class _StandExpansionCardState extends State<_StandExpansionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stand = widget.stand;
    final hasAvailable = stand.availableBikes > 0;
    final availColor =
        hasAvailable ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE0E0E0),
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header — always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: Radius.circular(_expanded ? 0 : 16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: availColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on_rounded,
                        color: availColor, size: 22),
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
                        const SizedBox(height: 2),
                        Text(
                          stand.description,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bikes available badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: availColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stand.availableBikes} bike${stand.availableBikes == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: availColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Dropdown — bikes list
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slot info row
                      Row(
                        children: [
                          const Icon(Icons.grid_view_rounded,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${stand.totalSlots} total slots',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (hasAvailable) ...[
                        ...stand.availableBikeIds
                            .map((id) => _BikeTile(bikeId: id)),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.do_not_disturb_rounded,
                                  color: Color(0xFFD32F2F), size: 18),
                              SizedBox(width: 10),
                              Text('No bikes available at this stand.',
                                  style:
                                      TextStyle(color: Color(0xFFD32F2F))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bike tile inside a stand dropdown ────────────────────────────────────────

class _BikeTile extends StatefulWidget {
  final String bikeId;
  const _BikeTile({required this.bikeId});

  @override
  State<_BikeTile> createState() => _BikeTileState();
}

class _BikeTileState extends State<_BikeTile> {
  bool _loading = false;

  Future<void> _onTap() async {
    setState(() => _loading = true);
    final bike = await ApiService().fetchBikeById(widget.bikeId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (bike == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BikeDetailsScreen(bike: bike)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _onTap,
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
            Text(
              widget.bikeId,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
            ),
            const Spacer(),
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF2E7D32)),
              )
            else ...[
              const Text('Tap to book',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.grey, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
