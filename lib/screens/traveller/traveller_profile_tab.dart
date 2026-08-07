import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../role_selection_screen.dart';

class TravellerProfileTab extends StatefulWidget {
  const TravellerProfileTab({super.key});

  @override
  State<TravellerProfileTab> createState() => _TravellerProfileTabState();
}

class _TravellerProfileTabState extends State<TravellerProfileTab> {
  final AuthRepository _authRepo = AuthRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showEditProfileDialog(BuildContext context, String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
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
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person, color: AppColors.travellerForestDark),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone, color: AppColors.travellerForestDark),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.travellerForestDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final uid = _authRepo.currentUser?.uid;
                          if (uid == null) return;

                          setDialogState(() => isSaving = true);
                          try {
                            await _firestore.collection('users').doc(uid).set({
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                            }, SetOptions(merge: true));

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully!'),
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
    final user = _authRepo.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.travellerForestDark,
        title: const Text('MY PROFILE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final displayName = data['name'] ?? user.displayName ?? user.email?.split('@').first ?? 'Traveller';
            final phone = data['phone'] ?? 'Not set';
            final email = user.email ?? 'N/A';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.travellerForestDark,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.travellerSoftMint, borderRadius: BorderRadius.circular(12)),
                    child: const Text('TRAVELLER ACCOUNT', style: TextStyle(color: AppColors.travellerForestDark, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: AppColors.travellerForestDark),
                          title: const Text('Full Name', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          subtitle: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.email_outlined, color: AppColors.travellerForestDark),
                          title: const Text('Email Address', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: AppColors.travellerForestDark),
                          title: const Text('Phone Number', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          subtitle: Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit, color: AppColors.travellerForestDark),
                      label: const Text('Edit Profile Details', style: TextStyle(color: AppColors.travellerForestDark, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.travellerForestDark),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showEditProfileDialog(context, displayName, phone == 'Not set' ? '' : phone),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await _authRepo.logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
