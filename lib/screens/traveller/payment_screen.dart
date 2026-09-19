import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import 'traveller_main_screen.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'RAZORPAY';
  bool _isProcessing = false;
  late Razorpay _razorpay;

  final _upiController = TextEditingController(text: 'user@upi');
  final _cardNumController = TextEditingController(text: '4532 •••• •••• 8892');

  BookingModel get booking => widget.booking;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _upiController.dispose();
    _cardNumController.dispose();
    super.dispose();
  }

  void _openRazorpayCheckout() {
    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Default test API key for sandbox testing
      'amount': (booking.totalPrice * 100).toInt(),
      'name': 'THE LOCALS',
      'description': 'Booking for ${booking.experienceTitle}',
      'prefill': {
        'contact': booking.travellerPhone.isNotEmpty ? booking.travellerPhone : '9876543210',
        'email': booking.travellerEmail.isNotEmpty ? booking.travellerEmail : 'traveller@thelocals.com',
      },
      'external': {
        'wallets': ['paytm']
      },
      'theme': {
        'color': '#13352B'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error launching Razorpay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Razorpay checkout: $e'), backgroundColor: AppColors.brandRed),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final paymentId = response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({
            'paymentStatus': 'paid',
            'paymentId': paymentId,
          });

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment recorded failed: $e'), backgroundColor: AppColors.brandRed),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment cancelled or failed: ${response.message ?? "Error"}'),
        backgroundColor: AppColors.brandRed,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet selected: ${response.walletName}')),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.travellerLightMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 54, color: AppColors.travellerForestDark),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Request Submitted!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment for "${booking.experienceTitle}" is successful. The request has been sent to Guide ${booking.guideName} for confirmation.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.travellerForestDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const TravellerMainScreen(initialTab: 2),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Go to My Bookings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate payment processing network delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({
            'paymentStatus': 'paid',
            'paymentId': 'sim_${DateTime.now().millisecondsSinceEpoch}',
          });

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment update failed: $e'), backgroundColor: AppColors.brandRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.travellerForestDark,
        title: const Text('SECURE CHECKOUT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Text(booking.experienceTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                    const SizedBox(height: 4),
                    Text('Date: ${booking.bookingDate} · ${booking.numberOfTravelers} Guests', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Payable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('₹${booking.totalPrice.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('SELECT PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
            const SizedBox(height: 12),

            _buildPaymentOption('RAZORPAY', 'Razorpay Gateway (UPI, Cards, NetBanking, Wallets)', Icons.verified_user),
            _buildPaymentOption('UPI', 'Manual UPI ID / VPA Entry', Icons.qr_code_2),
            _buildPaymentOption('CARD', 'Credit / Debit Cards Direct', Icons.credit_card),
            const SizedBox(height: 20),

            if (_selectedPaymentMethod == 'UPI') ...[
              const Text('UPI ID / VPA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
              const SizedBox(height: 6),
              TextField(
                controller: _upiController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payment, color: AppColors.travellerForestDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],

            if (_selectedPaymentMethod == 'CARD') ...[
              const Text('Card Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
              const SizedBox(height: 6),
              TextField(
                controller: _cardNumController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.credit_card, color: AppColors.travellerForestDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.travellerForestDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isProcessing
                    ? null
                    : () {
                        if (_selectedPaymentMethod == 'RAZORPAY') {
                          _openRazorpayCheckout();
                        } else {
                          _processPayment();
                        }
                      },
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Pay ₹${booking.totalPrice.toInt()} & Confirm Booking', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String key, String subtitle, IconData icon) {
    final isSelected = _selectedPaymentMethod == key;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? AppColors.travellerForestDark : Colors.transparent, width: 2),
      ),
      child: RadioListTile<String>(
        value: key,
        groupValue: _selectedPaymentMethod,
        activeColor: AppColors.travellerForestDark,
        title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        secondary: Icon(icon, color: AppColors.travellerForestDark),
        onChanged: (val) {
          if (val != null) setState(() => _selectedPaymentMethod = val);
        },
      ),
    );
  }
}
