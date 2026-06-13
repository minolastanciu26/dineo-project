import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final String restaurantName;
  final double total;
  final int userId;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.total,
    required this.userId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _savedCards = [];
  int? _selectedCardIndex;
  bool _loading = false;
  bool _processingPayment = false;
  bool _paymentSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('payment_cards') ?? '[]';
    final List<dynamic> decoded = jsonDecode(raw);
    setState(() {
      _savedCards = decoded.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _requestCashBill() async {
    setState(() => _loading = true);
    try {
      await _apiService.requestBill(
          orderId: widget.orderId, paymentMethod: 'cash');
      if (!mounted) return;
      _showCashConfirmation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error sending request. Please try again.'),
              backgroundColor: Color(0xFFB71C1C)),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showCashConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💵 Bill Requested',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Your waiter is on the way!\nPlease have your cash ready.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear cart
              final cart = Provider.of<CartProvider>(context, listen: false);
              cart.clearCart();
              // Go back to homepage (not the very first route, which could be Welcome/Login)
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            },
            child: const Text('OK',
                style: TextStyle(color: Color(0xFFB71C1C))),
          ),
        ],
      ),
    );
  }

  Future<void> _payWithCard() async {
    if (_selectedCardIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a card first.'),
            backgroundColor: Color(0xFFB71C1C)),
      );
      return;
    }

    setState(() => _processingPayment = true);

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 3));

    try {
      await _apiService.payWithCard(orderId: widget.orderId);
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _processingPayment = false;
      _paymentSuccess = true;
    });

    // Clear cart
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.clearCart();

    // Auto-navigate back to homepage after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_processingPayment) return _buildProcessingScreen();
    if (_paymentSuccess) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Payment',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.restaurantName,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.total.toStringAsFixed(2)} RON',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Total due',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),

                    // ── Cash Option ──────────────────────────────────
                    const Text('Pay at the table',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _loading ? null : _requestCashBill,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.payments_outlined,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Pay with Cash',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  Text('Waiter will bring your bill',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            if (_loading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Color(0xFFB71C1C),
                                    strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Card Option ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pay with Card',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PaymentMethodsScreen(),
                              ),
                            );
                            _loadCards();
                          },
                          child: const Text('Manage',
                              style:
                                  TextStyle(color: Color(0xFFB71C1C))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_savedCards.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'No saved cards.\nAdd a card in Payment Methods.',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...List.generate(_savedCards.length, (i) {
                        final card = _savedCards[i];
                        final selected = _selectedCardIndex == i;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCardIndex = i),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFB71C1C)
                                    : const Color(0xFF2A2A2A),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      card['type'] == 'Mastercard'
                                          ? 'MC'
                                          : 'V',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card['maskedNumber'] ??
                                            '**** **** **** ****',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${card['type'] ?? 'Card'} · Expires ${card['expiryDate'] ?? ''}',
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFFB71C1C)),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    if (_selectedCardIndex != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _payWithCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71C1C),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Pay ${widget.total.toStringAsFixed(2)} RON',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: const Color(0xFFB71C1C),
                strokeWidth: 3,
                backgroundColor: Colors.grey.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Processing Payment...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait, do not close the app',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFB71C1C), width: 2),
              ),
              child: const Icon(Icons.check,
                  color: Color(0xFFB71C1C), size: 56),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.total.toStringAsFixed(2)} RON paid at ${widget.restaurantName}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const Text(
              'Returning to home...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Payment Methods Screen (reusable from Profile too)
// ──────────────────────────────────────────────────────────────────────

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _cards = [];

  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('payment_cards') ?? '[]';
    final List<dynamic> decoded = jsonDecode(raw);
    setState(() => _cards = decoded.cast<Map<String, dynamic>>());
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('payment_cards', jsonEncode(_cards));
  }

  String _maskNumber(String number) {
    final clean = number.replaceAll(' ', '').replaceAll('-', '');
    if (clean.length < 4) return number;
    return '**** **** **** ${clean.substring(clean.length - 4)}';
  }

  String _detectType(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith('5')) return 'Mastercard';
    return 'Card';
  }

  void _showAddCardDialog() {
    _numberController.clear();
    _holderController.clear();
    _expiryController.clear();
    _cvvController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Card',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _inputField(_numberController, 'Card Number', '1234 5678 9012 3456'),
            const SizedBox(height: 12),
            _inputField(_holderController, 'Cardholder Name', 'JOHN DOE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _inputField(_expiryController, 'Expiry', 'MM/YY')),
                const SizedBox(width: 12),
                Expanded(
                    child: _inputField(_cvvController, 'CVV', '•••',
                        obscure: true)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_numberController.text.isEmpty ||
                      _holderController.text.isEmpty ||
                      _expiryController.text.isEmpty) return;

                  final newCard = {
                    'maskedNumber': _maskNumber(_numberController.text),
                    'cardholderName': _holderController.text.toUpperCase(),
                    'expiryDate': _expiryController.text,
                    'type': _detectType(_numberController.text),
                  };
                  setState(() => _cards.add(newCard));
                  _saveCards();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Card',
                    style:
                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label,
    String hint, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Payment Methods',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Color(0xFFB71C1C)),
                    onPressed: _showAddCardDialog,
                  ),
                ],
              ),
            ),

            if (_cards.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card_off,
                          color: Colors.grey, size: 64),
                      SizedBox(height: 16),
                      Text('No saved cards',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 18)),
                      SizedBox(height: 8),
                      Text(
                        'Tap + to add a card for quick payments',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                card['type'] == 'Mastercard'
                                    ? 'MC'
                                    : 'V',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card['maskedNumber'] ?? '**** **** **** ****',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${card['type'] ?? 'Card'} · ${card['cardholderName'] ?? ''} · Exp ${card['expiryDate'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            onPressed: () {
                              setState(() => _cards.removeAt(index));
                              _saveCards();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}