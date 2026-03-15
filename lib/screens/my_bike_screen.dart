import 'package:flutter/material.dart';
import 'list_your_bike_screen.dart';
import 'owner_rental_history_screen.dart';

class MyBikeScreen extends StatelessWidget {
  const MyBikeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('My Bike'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pedal_bike_rounded, color: Colors.white70, size: 36),
                  const SizedBox(height: 12),
                  const Text('Earn from Your Bike',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('List your personal cycle and let other students rent it. Earn Rs.8-10 per hour!',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Manage Your Bike',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20))),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.add_road_rounded,
              iconColor: const Color(0xFF2E7D32),
              title: 'List Your Bike',
              subtitle: 'Add your personal cycle to the campus rental network',
              buttonLabel: 'List Now',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ListYourBikeScreen())),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.currency_rupee_rounded,
              iconColor: const Color(0xFF6A1B9A),
              title: 'My Bike Earnings',
              subtitle: 'View rental history and withdraw your earnings',
              buttonLabel: 'View Earnings',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OwnerRentalHistoryScreen())),
            ),
            const SizedBox(height: 28),
            Text('How It Works',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20))),
            const SizedBox(height: 14),
            const _StepCard(step: '1', title: 'List Your Bike',
                desc: 'Submit your bike ID, select a parking stand, and upload a photo.'),
            const _StepCard(step: '2', title: 'Get Verified',
                desc: 'Our team verifies the bike details within 24 hours.'),
            const _StepCard(step: '3', title: 'Students Rent It',
                desc: 'Your bike appears on the app and students can book it.'),
            const _StepCard(step: '4', title: 'Earn Money',
                desc: 'You earn Rs.8-10 per hour. Withdraw anytime to your UPI.'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFF9A825), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('70% of rental revenue goes to you. 30% goes to campus maintenance.',
                        style: TextStyle(color: Color(0xFF795548), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.iconColor,
      required this.title, required this.subtitle,
      required this.buttonLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                          color: iconColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(buttonLabel, style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String desc;
  const _StepCard({required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
            child: Center(child: Text(step, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1B5E20))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
