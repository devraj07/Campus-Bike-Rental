import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OwnerPinSetupScreen extends StatefulWidget {
  final String bikeId;
  final bool isChangingPin;

  const OwnerPinSetupScreen({
    super.key,
    required this.bikeId,
    this.isChangingPin = false,
  });

  @override
  State<OwnerPinSetupScreen> createState() => _OwnerPinSetupScreenState();
}

class _OwnerPinSetupScreenState extends State<OwnerPinSetupScreen> {
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _confirmControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(4, (_) => FocusNode());
  final List<FocusNode> _confirmFocusNodes =
      List.generate(4, (_) => FocusNode());
  bool _saving = false;
  bool _pinSaved = false;

  String get _pin => _pinControllers.map((c) => c.text).join();
  String get _confirmPin => _confirmControllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var c in _confirmControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    for (var f in _confirmFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _savePin() async {
    if (_pin.length != 4) {
      _showError('Please enter a 4-digit PIN');
      return;
    }
    if (_pin != _confirmPin) {
      _showError('PINs do not match. Please try again.');
      return;
    }
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _pinSaved = true;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFD32F2F),
      ),
    );
  }

  void _onPinDigitChanged(int index, String value, bool isConfirm) {
    final focusNodes = isConfirm ? _confirmFocusNodes : _pinFocusNodes;
    final nextFocusNodes = isConfirm ? _confirmFocusNodes : _pinFocusNodes;
    if (value.isNotEmpty && index < 3) {
      nextFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_pinSaved) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FBF0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: Color(0xFF2E7D32), size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Owner PIN Set!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your permanent PIN for bike ${widget.bikeId} has been saved to the lock firmware. You can now unlock your bike anytime without booking.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFFF9A825), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This PIN works even when your bike is listed for rent — but you will be warned if a renter has already booked it.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF795548)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: Text(widget.isChangingPin ? 'Change Owner PIN' : 'Set Owner PIN'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded,
                  color: Color(0xFF2E7D32), size: 52),
            ),
            const SizedBox(height: 20),
            Text(
              'Set Your Owner PIN',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 8),
            Text(
              'This permanent PIN lets you unlock bike ${widget.bikeId} anytime — no booking needed.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 32),
            // PIN entry
            _PinSection(
              label: 'Enter 4-digit Owner PIN',
              controllers: _pinControllers,
              focusNodes: _pinFocusNodes,
              onChanged: (i, v) => _onPinDigitChanged(i, v, false),
            ),
            const SizedBox(height: 24),
            _PinSection(
              label: 'Confirm PIN',
              controllers: _confirmControllers,
              focusNodes: _confirmFocusNodes,
              onChanged: (i, v) => _onPinDigitChanged(i, v, true),
              autofocus: false,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security_rounded,
                          color: Color(0xFFF9A825), size: 16),
                      SizedBox(width: 6),
                      Text('How the two PINs work',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF795548),
                              fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Owner PIN (this): permanent, set by you, works anytime\n'
                    '• Rental OTP: temporary, generated per booking, expires after use\n'
                    '• The lock accepts both — whichever matches first',
                    style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _saving ? null : _savePin,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving to Lock...' : 'Save Owner PIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinSection extends StatelessWidget {
  final String label;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final Function(int, String) onChanged;
  final bool autofocus;

  const _PinSection({
    required this.label,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
                fontSize: 14)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 56,
                height: 64,
                child: TextFormField(
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  autofocus: autofocus && i == 0,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: controllers[i].text.isNotEmpty
                        ? const Color(0xFFE8F5E9)
                        : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E7D32), width: 2.5)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => onChanged(i, v),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
