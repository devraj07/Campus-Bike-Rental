import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ListYourBikeScreen extends StatefulWidget {
  const ListYourBikeScreen({super.key});

  @override
  State<ListYourBikeScreen> createState() => _ListYourBikeScreenState();
}

class _ListYourBikeScreenState extends State<ListYourBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bikeIdController = TextEditingController();
  String? _selectedStation;
  String? _selectedImageName;
  bool _submitting = false;
  final _api = ApiService();

  static const List<String> _stations = [
    'Academic Block A',
    'Hostel 1 Stand',
    'Library Gate',
    'Sports Complex',
    'Mess Block',
    'Admin Building',
  ];

  Future<void> _pickImage() async {
    // Simulate image pick
    setState(() => _selectedImageName = 'my_bike_photo.jpg');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final success = await _api.submitBikeListing(
        bikeId: _bikeIdController.text.trim(),
        station: _selectedStation!,
        imagePath: _selectedImageName,
      );
      if (!mounted) return;
      if (success) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Bike Listed!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your bike has been submitted for review. It will be listed once verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done',
                    style: TextStyle(color: Color(0xFF2E7D32))),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _bikeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('List Your Bike'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFF2E7D32), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'List your personal cycle on campus! Earn credits every time someone rents it.',
                        style: TextStyle(
                            color: Color(0xFF2E7D32), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Bike Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B5E20))),
              const SizedBox(height: 16),
              // Bike ID field
              TextFormField(
                controller: _bikeIdController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Bike ID / Name',
                  hintText: 'e.g. MY-BIKE-001',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a bike ID or name';
                  }
                  if (v.trim().length < 3) {
                    return 'Minimum 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Station dropdown
              DropdownButtonFormField<String>(
                value: _selectedStation,
                decoration: const InputDecoration(
                  labelText: 'Parking Stand Location',
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
                items: _stations
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStation = v),
                validator: (v) =>
                    v == null ? 'Please select a stand location' : null,
              ),
              const SizedBox(height: 24),
              Text('Bike Photo',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B5E20))),
              const SizedBox(height: 12),
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImageName != null
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE0E0E0),
                      width: _selectedImageName != null ? 2 : 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImageName == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: Color(0xFFBDBDBD), size: 44),
                            SizedBox(height: 8),
                            Text('Tap to upload bike photo',
                                style: TextStyle(
                                    color: Color(0xFFBDBDBD), fontSize: 14)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF2E7D32), size: 40),
                            const SizedBox(height: 8),
                            Text(
                              _selectedImageName!,
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Tap to change',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 28),
              // Terms
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Text(
                  '⚠️ By listing your bike, you agree to the IITGN Campus Bike Sharing terms. Your bike must be road-worthy and equipped with functional brakes and a lock.',
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF795548)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.upload_rounded),
                label: Text(_submitting ? 'Submitting…' : 'Submit Bike'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
