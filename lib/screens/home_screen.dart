import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bike.dart';
import '../services/api_service.dart';
import '../widgets/bike_card.dart';
import 'bike_details_screen.dart';
import 'stand_availability_screen.dart';
import 'ride_history_screen.dart';
import 'profile_screen.dart';
import 'my_bike_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const _HomeTab(),
    const StandAvailabilityScreen(),
    const RideHistoryScreen(),
    const MyBikeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pedal_bike_rounded),
            label: 'My Bike',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();
  final _apiService = ApiService();
  final User? _user = FirebaseAuth.instance.currentUser;
  List<Bike> _bikes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBikes();
  }

  Future<void> _loadBikes() async {
    setState(() => _isLoading = true);
    try {
      final bikes = await _apiService.fetchAvailableBikes(query: _searchQuery);
      setState(() => _bikes = bikes);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = _bikes.where((b) => b.isAvailable).length;
    final displayName = _user?.displayName ?? _user?.email?.split('@')[0] ?? 'User';
    final avatar = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF66BB6A),
                            child: Text(
                              avatar,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $displayName 👋',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '$available bikes available nearby',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by bike ID or station…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF9E9E9E)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadBikes();
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  _loadBikes();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.electric_bike_rounded,
                    label: '$available Available',
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 10),
                  const _StatChip(
                    icon: Icons.location_on_rounded,
                    label: '6 Stations',
                    color: Color(0xFF1565C0),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Nearby Bikes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  ),
                )
              : _bikes.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text('No bikes found')),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => BikeCard(
                          bike: _bikes[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BikeDetailsScreen(bike: _bikes[i]),
                            ),
                          ),
                        ),
                        childCount: _bikes.length,
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}