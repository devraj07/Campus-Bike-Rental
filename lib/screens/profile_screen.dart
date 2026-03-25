import 'package:flutter/material.dart';
import 'ride_history_screen.dart';
import 'list_your_bike_screen.dart';
import 'owner_rental_history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 44,
                      backgroundColor: Color(0xFF66BB6A),
                      child: Text(
                        'DR',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Devraj Rawat',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'devraj.rawat@iitgn.ac.in',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _ProfileStat(label: 'Rides', value: '5'),
                      Container(
                          width: 1, height: 40, color: Colors.white30,
                          margin: const EdgeInsets.symmetric(horizontal: 20)),
                      const _ProfileStat(label: 'Spent', value: '₹66'),
                      Container(
                          width: 1, height: 40, color: Colors.white30,
                          margin: const EdgeInsets.symmetric(horizontal: 20)),
                      const _ProfileStat(label: 'CO₂ Saved', value: '2.7g'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Menu section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.grey[500],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MenuCard(children: [
                    _MenuItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'My Rides',
                      iconColor: const Color(0xFF1565C0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RideHistoryScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.add_road_rounded,
                      label: 'List Your Bike',
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ListYourBikeScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.currency_rupee_rounded,
                      label: 'My Bike Earnings',
                      iconColor: const Color(0xFF6A1B9A),
                      subtitle: 'View rentals & withdraw earnings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const OwnerRentalHistoryScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Campus Wallet',
                      iconColor: const Color(0xFF00838F),
                      subtitle: 'Balance: ₹120.00',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    'Preferences',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.grey[500],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MenuCard(children: [
                    _MenuItem(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      iconColor: const Color(0xFFF57C00),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      iconColor: const Color(0xFF607D8B),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      iconColor: const Color(0xFF00838F),
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _MenuCard(children: [
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      iconColor: const Color(0xFFD32F2F),
                      labelColor: const Color(0xFFD32F2F),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                              'Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (_) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F)),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.eco_rounded,
                            color: Color(0xFF4CAF50), size: 22),
                        const SizedBox(height: 6),
                        Text(
                          'Campus Bike Rental – IITGN',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? labelColor;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.labelColor,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: labelColor ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
