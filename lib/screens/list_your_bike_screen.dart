import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../models/bike_state.dart';
import 'owner_pin_setup_screen.dart';

class ListYourBikeScreen extends StatefulWidget {
  const ListYourBikeScreen({super.key});

  @override
  State<ListYourBikeScreen> createState() => _ListYourBikeScreenState();
}

class _ListYourBikeScreenState extends State<ListYourBikeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _bikeIdController = TextEditingController();
  final _priceController = TextEditingController(text: '10');
  String? _selectedStation;
  File? _selectedImageFile;
  bool _submitting = false;
  bool _isListedForRent = false;
  bool _ownerPinSet = false;
  String _listedBikeId = '';
  double _pricePerHour = 10.0;
  final _api = ApiService();
  BikeStatus _bikeStatus = BikeStatus.docked;

  List<String> _stations = [];
  bool _loadingStations = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStations();
    _loadExistingBike();
  }

  Future<void> _loadExistingBike() async {
    try {
      final data = await _api.fetchOwnerBikeData(UserSession.userId);
      if (data == null || !mounted) return;
      final bikeId = data['id'] as String;
      final isListed = data['isListedForRent'] as bool? ?? false;
      final hasPin = (data['ownerPin'] as String?)?.isNotEmpty ?? false;
      final isAvailable = data['isAvailable'] as bool? ?? false;

      BikeStatus status;
      if (!isAvailable) {
        status = BikeStatus.onRide;
      } else if (isListed) {
        status = BikeStatus.docked;
      } else {
        status = BikeStatus.unplugged;
      }

      final price = (data['pricePerHour'] as num?)?.toDouble() ?? 10.0;
      setState(() {
        _listedBikeId = bikeId;
        _bikeIdController.text = bikeId;
        _selectedStation = data['station'] as String?;
        _isListedForRent = isListed;
        _ownerPinSet = hasPin;
        _bikeStatus = status;
        _pricePerHour = price;
        _priceController.text = price.toInt().toString();
      });
    } catch (_) {
      // No existing bike — form stays blank
    }
  }

  Future<void> _loadStations() async {
    try {
      final stands = await _api.fetchStands();
      if (mounted) {
        setState(() {
          _stations = stands.map((s) => s.standName).toList();
          _loadingStations = false;
          // If the saved station isn't in the list, clear it to avoid dropdown assert
          if (_selectedStation != null && !_stations.contains(_selectedStation)) {
            _selectedStation = null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStations = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bikeIdController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final bikeId = _bikeIdController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 10.0;
      await _api.submitBikeListing(
        bikeId: bikeId,
        station: _selectedStation!,
        pricePerHour: price,
        imagePath: _selectedImageFile?.path,
      );
      setState(() => _pricePerHour = price);
      if (!mounted) return;
      setState(() {
        _listedBikeId = bikeId;
        _isListedForRent = true;
        _bikeStatus = BikeStatus.docked;
      });
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bike submitted! Now set your Owner PIN and toggle listing.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toggleRentListing(bool value) async {
    if (_listedBikeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submit your bike first before toggling the listing.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (value && !_ownerPinSet) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerPinSetupScreen(bikeId: _listedBikeId),
        ),
      );
      if (result == true) {
        await _api.updateListingStatus(_listedBikeId, isListed: true);
        if (!mounted) return;
        setState(() {
          _ownerPinSet = true;
          _isListedForRent = true;
          _bikeStatus = BikeStatus.docked;
        });
      }
    } else {
      if (_bikeStatus == BikeStatus.reserved || _bikeStatus == BikeStatus.onRide) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.warning_rounded, color: Color(0xFFF9A825)),
              SizedBox(width: 8),
              Text('Cannot Unlist'),
            ]),
            content: const Text(
                'A renter has already booked your bike. You cannot unlist it until the booking is completed.'),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')),
            ],
          ),
        );
        return;
      }
      await _api.updateListingStatus(_listedBikeId, isListed: value);
      if (!mounted) return;
      setState(() => _isListedForRent = value);
    }
  }

  void _showEditRateDialog() {
    final controller =
        TextEditingController(text: _pricePerHour.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Hourly Rate',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '₹ ',
            suffixText: '/hr',
            hintText: '10',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 1 || value > 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Enter a valid rate between ₹1–₹200.')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await _api.updatePricePerHour(_listedBikeId, value);
                if (!mounted) return;
                setState(() {
                  _pricePerHour = value;
                  _priceController.text = value.toInt().toString();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rate updated to ₹${value.toInt()}/hr.'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update rate: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BikeStatus s) {
    switch (s) {
      case BikeStatus.docked: return const Color(0xFF2E7D32);
      case BikeStatus.reserved: return const Color(0xFFF9A825);
      case BikeStatus.onRide: return const Color(0xFF1565C0);
      case BikeStatus.unplugged: return const Color(0xFF9E9E9E);
      case BikeStatus.ownerUse: return const Color(0xFF6A1B9A);
    }
  }

  String _statusLabel(BikeStatus s) {
    switch (s) {
      case BikeStatus.docked: return 'Docked';
      case BikeStatus.reserved: return 'Reserved';
      case BikeStatus.onRide: return 'On Ride';
      case BikeStatus.unplugged: return 'Unplugged';
      case BikeStatus.ownerUse: return 'Owner Use';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('List Your Bike'),
        backgroundColor: const Color(0xFF2E7D32),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Submit Bike'),
            Tab(text: 'Manage Listing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Submit
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFF2E7D32), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            'List your personal cycle and earn money every time a student rents it!',
                            style: TextStyle(
                                color: Color(0xFF2E7D32), fontSize: 13)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _bikeIdController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        labelText: 'Bike ID / Name',
                        hintText: 'e.g. MY-BIKE-001',
                        prefixIcon: Icon(Icons.tag_rounded)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter a bike ID';
                      if (v.trim().length < 3) return 'Minimum 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('${_loadingStations}_$_selectedStation'),
                    initialValue: _loadingStations ? null : _selectedStation,
                    decoration: InputDecoration(
                        labelText: 'Parking Stand Location',
                        prefixIcon: const Icon(Icons.location_on_rounded),
                        hintText: _loadingStations ? 'Loading stands…' : null),
                    items: _stations
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: _loadingStations
                        ? null
                        : (v) => setState(() => _selectedStation = v),
                    validator: (v) => v == null ? 'Please select a location' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hourly Rate (₹)',
                      hintText: 'e.g. 10',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                      suffixText: '/hr',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v?.trim() ?? '');
                      if (val == null || val < 1 || val > 200) {
                        return 'Enter a rate between ₹1 and ₹200';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedImageFile != null
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE0E0E0),
                          width: _selectedImageFile != null ? 2 : 1,
                        ),
                      ),
                      child: _selectedImageFile == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    color: Color(0xFFBDBDBD), size: 40),
                                SizedBox(height: 8),
                                Text('Tap to pick bike photo from gallery',
                                    style: TextStyle(color: Color(0xFFBDBDBD))),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Tap to change',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: const Text(
                      'By listing your bike, you agree to the IITGN Campus Bike Sharing terms.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.upload_rounded),
                    label: Text(_submitting ? 'Submitting...' : 'Submit Bike'),
                  ),
                ],
              ),
            ),
          ),
          // Tab 2: Manage
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Bike status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.electric_bike_rounded,
                                color: Color(0xFF2E7D32), size: 24),
                            const SizedBox(width: 10),
                            Text(
                              _bikeIdController.text.isNotEmpty
                                  ? _bikeIdController.text
                                  : 'Your Bike',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B5E20)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _statusColor(_bikeStatus).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                        color: _statusColor(_bikeStatus),
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _statusLabel(_bikeStatus),
                                    style: TextStyle(
                                        color: _statusColor(_bikeStatus),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_selectedStation ?? 'Not selected',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Hourly rate card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.currency_rupee_rounded,
                              color: Color(0xFF6A1B9A), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hourly Rate',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Color(0xFF1B5E20))),
                              Text('₹${_pricePerHour.toInt()} per hour',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _listedBikeId.isEmpty
                              ? null
                              : () => _showEditRateDialog(),
                          child: const Text('Edit',
                              style: TextStyle(
                                  color: Color(0xFF6A1B9A),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // List for Rent toggle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isListedForRent
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isListedForRent
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: _isListedForRent
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('List for Rent',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Color(0xFF1B5E20))),
                                  Text('Make your bike visible to renters',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isListedForRent,
                              onChanged: _toggleRentListing,
                              activeThumbColor: const Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isListedForRent
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isListedForRent
                                    ? Icons.check_circle_rounded
                                    : Icons.visibility_off_rounded,
                                color: _isListedForRent
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isListedForRent
                                      ? 'Visible to renters. Earning 70% per rental.'
                                      : 'Hidden from renters. Toggle ON to earn.',
                                  style: TextStyle(
                                      color: _isListedForRent
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Owner PIN card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _ownerPinSet
                                    ? const Color(0xFFEDE7F6)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.lock_person_rounded,
                                  color: _ownerPinSet
                                      ? const Color(0xFF6A1B9A)
                                      : Colors.grey,
                                  size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Owner PIN',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Color(0xFF1B5E20))),
                                  Text(
                                    _ownerPinSet
                                        ? 'Set — unlock your bike anytime'
                                        : 'Not set — required before listing',
                                    style: TextStyle(
                                        color: _ownerPinSet
                                            ? const Color(0xFF6A1B9A)
                                            : Colors.grey,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerPinSetupScreen(
                                      bikeId: _bikeIdController.text.isNotEmpty
                                          ? _bikeIdController.text
                                          : 'YOUR-BIKE',
                                      isChangingPin: _ownerPinSet,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  setState(() => _ownerPinSet = true);
                                }
                              },
                              child: Text(
                                _ownerPinSet ? 'Change' : 'Set PIN',
                                style: const TextStyle(
                                    color: Color(0xFF6A1B9A),
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        if (!_ownerPinSet) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFE082)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFF9A825), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Set your Owner PIN so you can always access your own bike, even when listed for rent.',
                                  style: TextStyle(
                                      color: Color(0xFF795548), fontSize: 12),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Status guide
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bike Status Guide',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1B5E20))),
                        const SizedBox(height: 14),
                        const _StateRow(color: Color(0xFF2E7D32), label: 'Docked', desc: 'At stand, ready to rent'),
                        const _StateRow(color: Color(0xFFF9A825), label: 'Reserved', desc: 'Renter booked, OTP sent to lock'),
                        const _StateRow(color: Color(0xFF1565C0), label: 'On Ride', desc: 'OTP entered, billing running'),
                        const _StateRow(color: Color(0xFF9E9E9E), label: 'Unplugged', desc: 'Wire pulled, not yet unlocked'),
                        const _StateRow(color: Color(0xFF6A1B9A), label: 'Owner Use', desc: 'You unlocked with owner PIN'),
                      ],
                    ),
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

class _StateRow extends StatelessWidget {
  final Color color;
  final String label;
  final String desc;

  const _StateRow({required this.color, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          const SizedBox(width: 8),
          Text('— $desc',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
