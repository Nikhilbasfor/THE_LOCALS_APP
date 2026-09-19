import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/privacy_policy_dialog.dart';
import '../role_selection_screen.dart';

class TravellerProfileTab extends StatefulWidget {
  const TravellerProfileTab({super.key});

  @override
  State<TravellerProfileTab> createState() => _TravellerProfileTabState();
}

class _TravellerProfileTabState extends State<TravellerProfileTab> {
  final AuthRepository _authRepo = AuthRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploadingPhoto = false;

  static const List<String> _availableInterests = [
    'Trekking & Hiking',
    'Culture & Heritage',
    'Local Food & Street Eats',
    'Photography',
    'Nature & Wildlife',
    'Offbeat Trails',
    'Spiritual Journeys',
    'Camping & Stargazing',
    'Adventure Sports',
    'Village Living',
  ];

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final user = _authRepo.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).set({
        'profilePicUrl': downloadUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.brandGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.brandRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.travellerForestDark),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.travellerForestDark),
                title: const Text('Take a new photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.travellerForestDark),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInterestsBottomSheet(BuildContext context, List<String> currentInterests) {
    final selected = List<String>.from(currentInterests);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Travel Interests',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.travellerForestDark),
                        ),
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final user = _authRepo.currentUser;
                                  if (user == null) return;
                                  setModalState(() => isSaving = true);
                                  try {
                                    await _firestore.collection('users').doc(user.uid).set({
                                      'interests': selected,
                                    }, SetOptions(merge: true));
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save', style: TextStyle(color: AppColors.travellerForestDark, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select what excites you most when exploring destinations:',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: _availableInterests.map((interest) {
                            final isSelected = selected.contains(interest);
                            return FilterChip(
                              label: Text(interest),
                              selected: isSelected,
                              selectedColor: AppColors.travellerSoftMint,
                              backgroundColor: Colors.grey[100],
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.travellerForestDark : AppColors.textMain,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12.5,
                              ),
                              checkmarkColor: AppColors.travellerForestDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppColors.travellerForestDark : Colors.black12,
                                ),
                              ),
                              onSelected: (val) {
                                setModalState(() {
                                  if (val) {
                                    selected.add(interest);
                                  } else {
                                    selected.remove(interest);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName, String currentPhone, String currentBio) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final bioController = TextEditingController(text: currentBio);
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
              content: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 14),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'About You / Bio',
                        hintText: 'Share a bit about your travel style...',
                        prefixIcon: const Icon(Icons.notes, color: AppColors.travellerForestDark),
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
                              'bio': bioController.text.trim(),
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
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandRed),
              ),
              content: const Text(
                'Are you sure you want to delete your account permanently? This action cannot be undone and will immediately remove your profile, bookings, and all associated personal data.',
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
                                  content: Text('Your account has been deleted permanently.'),
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
            final bio = (data['bio'] as String?) ?? '';
            final profilePicUrl = (data['profilePicUrl'] as String?) ?? '';
            final interests = (data['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Avatar with Photo Upload & Camera Action
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showPhotoOptions(context),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.travellerForestDark,
                            backgroundImage: profilePicUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profilePicUrl)
                                : null,
                            child: profilePicUrl.isEmpty
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showPhotoOptions(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.travellerForestDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 20),

                  // Account Details Card
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

                  // Bio Card
                  const SizedBox(height: 14),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.notes, size: 18, color: AppColors.travellerForestDark),
                              SizedBox(width: 8),
                              Text(
                                'About Me',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.travellerForestDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio.isNotEmpty ? bio : 'No bio added yet. Tap Edit below to share your travel style!',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: bio.isNotEmpty ? AppColors.textMain : AppColors.textMuted,
                              fontStyle: bio.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Travel Interests Card
                  const SizedBox(height: 14),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.favorite_outline, size: 18, color: AppColors.travellerForestDark),
                                  SizedBox(width: 8),
                                  Text(
                                    'Travel Interests',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.travellerForestDark),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _showInterestsBottomSheet(context, interests),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Edit', style: TextStyle(color: AppColors.travellerForestDark, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (interests.isEmpty)
                            const Text(
                              'No interests selected yet. Tap Edit to personalize your experience.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: interests.map((i) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.travellerSoftMint,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    i,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.travellerForestDark),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
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
                      onPressed: () => _showEditProfileDialog(context, displayName, phone == 'Not set' ? '' : phone, bio),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.privacy_tip_outlined, color: AppColors.headerNavy),
                      label: const Text('Privacy Policy & Data Rights', style: TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => PrivacyPolicyDialog.show(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_forever_outlined, color: AppColors.brandRed),
                      label: const Text('Delete Account', style: TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.brandRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showDeleteAccountDialog(context),
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
