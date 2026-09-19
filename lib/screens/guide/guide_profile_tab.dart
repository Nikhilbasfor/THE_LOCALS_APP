import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/privacy_policy_dialog.dart';
import '../role_selection_screen.dart';

class GuideProfileTab extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const GuideProfileTab({super.key, required this.onNavigateToTab});

  @override
  State<GuideProfileTab> createState() => _GuideProfileTabState();
}

class _GuideProfileTabState extends State<GuideProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _authRepo = AuthRepository();

  void _showDeleteAccountDialog(BuildContext context) {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Delete Guide Account',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandRed),
              ),
              content: const Text(
                'Are you sure you want to delete your guide account permanently? This action cannot be undone and will immediately remove your guide profile, hosted experiences, and all associated personal data.',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMain),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await _authRepo.deleteAccount();
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your guide account has been deleted permanently.'),
                                  backgroundColor: AppColors.brandGreen,
                                ),
                              );
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().contains('requires-recent-login')
                                        ? 'Please log out and log in again before deleting your account.'
                                        : 'Failed to delete account: $e',
                                  ),
                                  backgroundColor: AppColors.brandRed,
                                ),
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGuideProfileDialog(
    BuildContext context,
    String currentName,
    String currentPhone,
    String currentCity,
    String currentState,
    String currentBio,
    String currentPic,
  ) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final cityController = TextEditingController(text: currentCity);
    final stateController = TextEditingController(text: currentState);
    final bioController = TextEditingController(text: currentBio);
    final picController = TextEditingController(text: currentPic);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Edit Guide Profile',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.headerNavy),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person, color: AppColors.headerNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone, color: AppColors.headerNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
                              prefixIcon: const Icon(Icons.location_city, color: AppColors.headerNavy),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            decoration: InputDecoration(
                              labelText: 'State',
                              prefixIcon: const Icon(Icons.map, color: AppColors.headerNavy),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: picController,
                      decoration: InputDecoration(
                        labelText: 'Profile Picture Image URL',
                        prefixIcon: const Icon(Icons.image, color: AppColors.headerNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio & Summary',
                        prefixIcon: const Icon(Icons.description, color: AppColors.headerNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final uid = _auth.currentUser?.uid;
                          if (uid == null) return;

                          setDialogState(() => isSaving = true);
                          try {
                            await _firestore.collection('users').doc(uid).set({
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'city': cityController.text.trim(),
                              'state': stateController.text.trim(),
                              'profilePicUrl': picController.text.trim(),
                              'bio': bioController.text.trim(),
                            }, SetOptions(merge: true));

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Guide profile updated!'),
                                  backgroundColor: AppColors.brandGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.brandRed),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = userData['name'] ?? userData['fullName'] ?? 'Guide';
        final email = userData['email'] ?? _auth.currentUser?.email ?? '—';
        final userCity = userData['city'] ?? '';
        final userState = userData['state'] ?? '';
        final phone = userData['phone'] ?? '';
        final locationText = userCity.isNotEmpty
            ? (userState.isNotEmpty ? '$userCity, $userState' : userCity)
            : (userState.isNotEmpty ? userState : 'Location not set');
        final bio = userData['bio'] ?? 'Passionate to travel and make people travel.';
        final profileImg = userData['profilePicUrl'] ?? userData['profileImage'] ?? '';

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.headerNavy, width: 3),
                      color: Colors.grey[200],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
                      child: profileImg.isEmpty
                          ? const Icon(Icons.person, color: AppColors.headerNavy, size: 48)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.headerNavy.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'GUIDE',
                          style: TextStyle(
                            color: AppColors.headerNavy,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        locationText,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    color: AppColors.headerNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16, color: AppColors.headerNavy),
                  label: const Text('Edit Profile', style: TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold)),
                  onPressed: () => _showEditGuideProfileDialog(
                    context,
                    name,
                    phone,
                    userCity,
                    userState,
                    bio,
                    profileImg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              style: const TextStyle(color: AppColors.textMain, fontSize: 15, height: 1.4),
            ),

            const SizedBox(height: 24),

            // Quick Navigation
            const Text(
              'Navigate',
              style: TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.explore,
              label: 'My Experiences',
              onTap: () => widget.onNavigateToTab(1),
            ),
            _buildMenuItem(
              icon: Icons.confirmation_number,
              label: 'My Bookings',
              onTap: () => widget.onNavigateToTab(2),
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy & Data Rights',
              onTap: () => PrivacyPolicyDialog.show(context),
            ),
            _buildMenuItem(
              icon: Icons.delete_forever_outlined,
              label: 'Delete Account',
              iconColor: AppColors.brandRed,
              textColor: AppColors.brandRed,
              onTap: () => _showDeleteAccountDialog(context),
            ),

            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _authRepo.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed.withValues(alpha: 0.15),
                  foregroundColor: AppColors.brandRed,
                  side: const BorderSide(color: AppColors.brandRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.headerNavy;
    final effectiveTextColor = textColor ?? AppColors.textMain;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveIconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: effectiveIconColor, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(color: effectiveTextColor, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
