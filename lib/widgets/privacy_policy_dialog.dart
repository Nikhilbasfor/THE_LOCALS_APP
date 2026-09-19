import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const PrivacyPolicyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.privacy_tip_outlined, color: AppColors.headerNavy),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.headerNavy),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'THE LOCALS Privacy & Data Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
              ),
              SizedBox(height: 6),
              Text(
                'Last updated: 2026\n\n'
                'Welcome to THE LOCALS. We are committed to safeguarding your privacy and ensuring transparency regarding how your information is handled.\n\n'
                '1. Information We Collect\n'
                '• Account Details: When you register as a Traveller or Local Guide, we collect your name, email address, phone number, and account role.\n'
                '• Guide Credentials: For local guides, we collect bio details, operating state/region, experience years, and verification documents to verify authenticity.\n'
                '• Bookings & Interactions: Details about your booked itineraries, dates, participant counts, and messages exchanged between travellers and guides.\n'
                '• Location: With your permission, we access device location to discover nearby guides and curated experiences.\n\n'
                '2. How We Use Information\n'
                '• To authenticate users and deliver our booking and tour guide matching services.\n'
                '• To verify the credentials of local guides ensuring safety and quality.\n'
                '• To process reservations and send important notifications about your bookings.\n\n'
                '3. Account & Data Deletion\n'
                'In accordance with Apple App Store and Google Play guidelines, you have full control over your data. You can delete your account and associated personal data at any time directly within the app by going to your Profile settings and selecting "Delete Account". All profile records and authentication credentials are permanently removed from our active databases upon confirmation.\n\n'
                '4. Data Security\n'
                'We use industry-standard encryption and Firebase Cloud security rules to safeguard all stored records against unauthorized access.\n\n'
                '5. Contact Us\n'
                'If you have questions regarding this Privacy Policy or your data rights, please contact our support team at support@thelocalsapp.com.',
                style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
        ),
      ],
    );
  }
}
