import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import 'guide_main_screen.dart';
import '../role_selection_screen.dart';

class GuideOnboardingScreen extends StatefulWidget {
  final UserModel? initialUser;
  final int initialStep;

  const GuideOnboardingScreen({
    super.key,
    this.initialUser,
    this.initialStep = 1,
  });

  @override
  State<GuideOnboardingScreen> createState() => _GuideOnboardingScreenState();
}

class _GuideOnboardingScreenState extends State<GuideOnboardingScreen> {
  int _currentStep = 1;
  bool _isSubmitting = false;

  // Step 1 Controllers
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _languagesController = TextEditingController();
  final _expYearsController = TextEditingController();
  String _selectedBirthState = 'Himachal Pradesh';

  // Step 2 Selection Lists
  final List<String> _allRegions = ['Himachal Pradesh', 'Uttarakhand', 'Ladakh', 'Sikkim', 'Kashmir', 'Arunachal Pradesh'];
  final List<String> _selectedRegions = [];
  final List<String> _allSpecialties = ['Trekking & Hiking', 'Cultural & Heritage', 'Photography', 'Camping & Wildlife', 'Spiritual Tours', 'Extreme Adventure'];
  final List<String> _selectedSpecialties = [];

  // Step 3 Profile Image
  final _profilePicController = TextEditingController();

  // Step 4 Aadhaar Verification
  final _aadhaarNumController = TextEditingController();
  final _aadhaarFrontUrlController = TextEditingController();
  final _aadhaarBackUrlController = TextEditingController();

  final List<String> _himalayanStates = [
    'Himachal Pradesh',
    'Uttarakhand',
    'Ladakh',
    'Jammu & Kashmir',
    'Sikkim',
    'Arunachal Pradesh',
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.initialUser != null) {
      final u = widget.initialUser!;
      _phoneController.text = u.phone;
      _bioController.text = u.bio;
      _languagesController.text = u.languages.join(', ');
      _expYearsController.text = u.experienceYears > 0 ? '${u.experienceYears}' : '';
      if (u.birthState.isNotEmpty) _selectedBirthState = u.birthState;
      _selectedRegions.addAll(u.regions);
      _selectedSpecialties.addAll(u.specialties);
      _profilePicController.text = u.profilePicUrl;
      _aadhaarNumController.text = u.aadhaarNumber;
      _aadhaarFrontUrlController.text = u.aadhaarFrontUrl;
      _aadhaarBackUrlController.text = u.aadhaarBackUrl;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _languagesController.dispose();
    _expYearsController.dispose();
    _profilePicController.dispose();
    _aadhaarNumController.dispose();
    _aadhaarBackUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveStepProgress(int nextStep) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'languages': _languagesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'experienceYears': int.tryParse(_expYearsController.text.trim()) ?? 0,
        'birthState': _selectedBirthState,
        'regions': _selectedRegions,
        'specialties': _selectedSpecialties,
        'profilePicUrl': _profilePicController.text.trim(),
        'aadhaarNumber': _aadhaarNumController.text.trim(),
        'aadhaarFrontUrl': _aadhaarFrontUrlController.text.trim(),
        'aadhaarBackUrl': _aadhaarBackUrlController.text.trim(),
      };

      if (nextStep == 5) {
        data['onboardingComplete'] = true;
        data['verified'] = false; // Requires Admin Approval
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _currentStep = nextStep;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save progress: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        title: Text(
          _currentStep < 5 ? 'GUIDE ONBOARDING (STEP $_currentStep/4)' : 'VERIFICATION STATUS',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
      default:
        return _buildStep5VerificationPending();
    }
  }

  // STEP 1: Personal Info
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal & Professional Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Introduce yourself to Himalayan travellers seeking authentic local guidance.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildTextField('Years of Guiding Experience', _expYearsController, Icons.work_history, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField('Languages Spoken (comma separated)', _languagesController, Icons.translate, hint: 'e.g. Hindi, English, Pahari'),
        const SizedBox(height: 16),
        const Text('Native / Birth State', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black26),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBirthState,
              dropdownColor: Colors.white,
              isExpanded: true,
              style: const TextStyle(color: AppColors.textMain),
              items: _himalayanStates.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBirthState = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField('Guide Bio & Summary', _bioController, Icons.description, maxLines: 4, hint: 'Describe your expertise in trekking, local culture, and mountain safety...'),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () => _saveStepProgress(2),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Next: Regions & Specialties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // STEP 2: Regions & Specialties
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Regional Expertise & Specialties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Select the Himalayan regions you specialize in and your core activities.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        const Text('Regions You Guide In:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allRegions.map((reg) {
            final isSelected = _selectedRegions.contains(reg);
            return FilterChip(
              label: Text(reg),
              selected: isSelected,
              selectedColor: AppColors.headerNavy,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textMain),
              backgroundColor: Colors.white,
              onSelected: (sel) {
                setState(() {
                  sel ? _selectedRegions.add(reg) : _selectedRegions.remove(reg);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Your Guiding Specialties:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allSpecialties.map((spec) {
            final isSelected = _selectedSpecialties.contains(spec);
            return FilterChip(
              label: Text(spec),
              selected: isSelected,
              selectedColor: AppColors.headerNavy,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textMain),
              backgroundColor: Colors.white,
              onSelected: (sel) {
                setState(() {
                  sel ? _selectedSpecialties.add(spec) : _selectedSpecialties.remove(spec);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.headerNavy), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => setState(() => _currentStep = 1),
                child: const Text('Back', style: TextStyle(color: AppColors.headerNavy)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => _saveStepProgress(3),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Next: Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: Profile Photo
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Provide a clear headshot image URL for your guide badge.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: _profilePicController.text.isNotEmpty ? NetworkImage(_profilePicController.text) : null,
            child: _profilePicController.text.isEmpty ? const Icon(Icons.person, size: 50, color: AppColors.headerNavy) : null,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField('Profile Picture Image URL', _profilePicController, Icons.image, hint: 'https://...', onChanged: (_) => setState(() {})),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.headerNavy), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => setState(() => _currentStep = 2),
                child: const Text('Back', style: TextStyle(color: AppColors.headerNavy)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => _saveStepProgress(4),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Next: Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: Aadhaar Identity Verification Upload
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identity Verification (Aadhaar)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Government ID verification is required to maintain safety across Himalayan expeditions.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        _buildTextField('Aadhaar Card Number (12 Digits)', _aadhaarNumController, Icons.badge, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField('Aadhaar Front Image URL', _aadhaarFrontUrlController, Icons.upload_file, hint: 'https://...'),
        const SizedBox(height: 16),
        _buildTextField('Aadhaar Back Image URL', _aadhaarBackUrlController, Icons.upload_file, hint: 'https://...'),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.headerNavy), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => setState(() => _currentStep = 3),
                child: const Text('Back', style: TextStyle(color: AppColors.headerNavy)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => _saveStepProgress(5),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit For Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 5: Verification Pending Status Screen
  Widget _buildStep5VerificationPending() {
    final user = widget.initialUser;
    final isRejected = user?.rejectionReason != null && user!.rejectionReason!.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isRejected ? Colors.red.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected ? Icons.error_outline : Icons.hourglass_top,
                size: 64,
                color: isRejected ? Colors.redAccent : Colors.amber[800],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRejected ? 'Verification Revision Required' : 'Verification Under Review',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isRejected
                  ? 'Reason: ${user.rejectionReason}'
                  : 'Thank you for completing your guide profile! Our admin team is verifying your Aadhaar credentials. You will gain access to your Guide Dashboard once approved.',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isRejected)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text('Edit Verification Details', style: TextStyle(color: Colors.white)),
                onPressed: () => setState(() => _currentStep = 1),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.headerNavy)),
              child: const Text('Check Status / Refresh', style: TextStyle(color: AppColors.headerNavy)),
              onPressed: () async {
                final u = FirebaseAuth.instance.currentUser;
                if (u != null) {
                  final doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
                  if (doc.exists && doc.data() != null) {
                    final freshUser = UserModel.fromMap(doc.data()!, doc.id);
                    if (freshUser.verified && mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const GuideMainScreen()),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textMain),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.headerNavy, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
          ),
        ),
      ],
    );
  }
}
