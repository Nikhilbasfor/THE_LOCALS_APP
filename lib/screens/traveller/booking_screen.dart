import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/experience_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/booking_repository.dart';
import '../../theme/app_colors.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final ExperienceModel experience;

  const BookingScreen({super.key, required this.experience});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final AuthRepository _authRepo = AuthRepository();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  int _travelersCount = 1;
  bool _isSubmitting = false;

  ExperienceModel get exp => widget.experience;

  double get totalPrice => exp.price * _travelersCount;

  Future<void> _handleConfirmBooking() async {
    final user = _authRepo.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place a booking.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProfile = await _authRepo.getUserProfile(user.uid);

      final newBooking = BookingModel(
        experienceId: exp.id,
        experienceTitle: exp.title,
        experienceImage: exp.images.isNotEmpty ? exp.images.first : '',
        travellerId: user.uid,
        travellerName: userProfile?.name ?? user.email ?? 'Traveller',
        travellerEmail: user.email ?? '',
        travellerPhone: userProfile?.phone ?? '',
        guideId: exp.guideId,
        guideName: exp.guideName,
        bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        numberOfTravelers: _travelersCount,
        totalPrice: totalPrice,
        status: 'pending',
        specialRequests: _notesController.text.trim(),
      );

      final createdDocId = await _bookingRepo.createBooking(newBooking);

      if (!mounted) return;

      final bookingWithId = BookingModel(
        id: createdDocId,
        experienceId: newBooking.experienceId,
        experienceTitle: newBooking.experienceTitle,
        experienceImage: newBooking.experienceImage,
        travellerId: newBooking.travellerId,
        travellerName: newBooking.travellerName,
        travellerEmail: newBooking.travellerEmail,
        travellerPhone: newBooking.travellerPhone,
        guideId: newBooking.guideId,
        guideName: newBooking.guideName,
        bookingDate: newBooking.bookingDate,
        numberOfTravelers: newBooking.numberOfTravelers,
        totalPrice: newBooking.totalPrice,
        status: newBooking.status,
        specialRequests: newBooking.specialRequests,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentScreen(booking: bookingWithId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.brandRed),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.travellerForestDark,
        title: const Text('CONFIRM BOOKING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: exp.images.isNotEmpty ? exp.images.first : 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 70,
                            height: 70,
                            color: AppColors.travellerForestDark.withValues(alpha: 0.1),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 70,
                            height: 70,
                            color: AppColors.travellerForestDark,
                            child: const Icon(Icons.image, color: Colors.white54, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('Guide: ${exp.guideName}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Selector
              const Text('Select Journey Start Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.travellerForestDark),
                      const SizedBox(width: 12),
                      Text(DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.edit, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Travelers Counter
              const Text('Number of Travelers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Text('Travelers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.travellerForestDark),
                      onPressed: _travelersCount > 1 ? () => setState(() => _travelersCount--) : null,
                    ),
                    Text('$_travelersCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.travellerForestDark),
                      onPressed: _travelersCount < exp.maxGroupSize ? () => setState(() => _travelersCount++) : null,
                    ),
                  ],
                ),
              ),
              if (exp.maxGroupSize > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Maximum group size: ${exp.maxGroupSize} travelers',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 20),

              // Special Requests
              const Text('Special Requests / Notes (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mention dietary requirements, pickup points or special needs...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),

              // Price Breakdown Card
              Card(
                color: AppColors.travellerLightMint,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${exp.price.toInt()} × $_travelersCount Travelers', style: const TextStyle(fontSize: 13, color: AppColors.textMain)),
                          Text('₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount Payable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                          Text('₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleConfirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.travellerForestDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm & Submit Booking Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
