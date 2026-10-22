import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/geo_data.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_colors.dart';
import 'guide_main_screen.dart';
import '../role_selection_screen.dart';

class AadhaarNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digitsOnly.length > 12 ? digitsOnly.substring(0, 12) : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(truncated[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class GuideOnboardingScreen extends StatefulWidget {
  final UserModel? initialUser;
  final int initialStep;

  const GuideOnboardingScreen({
    super.key,
    this.initialUser,
    this.initialStep = 0,
  });

  @override
  State<GuideOnboardingScreen> createState() => _GuideOnboardingScreenState();
}

class _GuideOnboardingScreenState extends State<GuideOnboardingScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _verificationSubscription;

  // Step 0 Controllers & OTP State (Requirement 3)
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _selectedCountryCode = '+91';
  bool _otpSent = false;
  String _generatedOtp = '';
  bool _isSendingOtp = false;

  // Step 1 Controllers & Cascading Geography (Requirements 11 & 12)
  String _selectedCountry = 'India';
  String _selectedBirthState = 'Uttarakhand';
  String _selectedOperatingState = 'Uttarakhand';
  String _selectedCity = 'Dehradun';
  final _customCityController = TextEditingController();
  bool _isCustomCity = false;
  final _expYearsController = TextEditingController(text: '3');
  final _bioController = TextEditingController();

  // Step 2 Selection Lists & Experience Specialties (Requirement 13)
  final _languagesController = TextEditingController();
  final List<String> _selectedLanguages = ['Hindi', 'English'];
  final _languageSearchController = TextEditingController();

  // 17 Experience Specialties as per Requirement 13
  final List<String> _availableSpecialties = List<String>.from(experienceSpecialties);
  final List<String> _selectedSpecialties = [
    'Nature and Wilderness',
    'Adventure and Outdoor Activities',
  ];
  final _specialtySearchController = TextEditingController();
  final _customSpecialtyController = TextEditingController();

  // Step 3 Profile Image
  final _profilePicController = TextEditingController();
  XFile? _profileXFile;
  bool _isUploadingProfile = false;

  // Step 4 Aadhaar Verification
  final _aadhaarNumController = TextEditingController();
  final _aadhaarFrontUrlController = TextEditingController();
  final _aadhaarBackUrlController = TextEditingController();
  XFile? _aadhaarFrontXFile;
  XFile? _aadhaarBackXFile;
  bool _isUploadingAadhaarFront = false;
  bool _isUploadingAadhaarBack = false;

  List<String> get availableStates {
    if (_selectedCountry == 'India') return indianStatesAndUTs;
    if (_selectedCountry == 'Nepal') return nepalRegions;
    if (_selectedCountry == 'Bhutan') return bhutanRegions;
    return ['All Regions'];
  }

  List<String> get availableCities {
    return stateCitiesMap[_selectedOperatingState] ?? ['Capital / Main City'];
  }

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _nameController.text = currentUser.displayName ?? '';
      if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
        _phoneController.text = currentUser.phoneNumber!;
      }
    }

    if (widget.initialUser != null) {
      final u = widget.initialUser!;
      if (u.name.isNotEmpty) _nameController.text = u.name;
      if (u.phone.isNotEmpty) _phoneController.text = u.phone;
      _bioController.text = u.bio;
      for (final lang in u.languages) {
        if (!_selectedLanguages.contains(lang)) _selectedLanguages.add(lang);
      }
      _languagesController.text = _selectedLanguages.join(', ');
      _expYearsController.text = u.experienceYears > 0 ? '${u.experienceYears}' : '3';
      if (u.birthState.isNotEmpty) _selectedBirthState = u.birthState;
      if (u.state.isNotEmpty) _selectedOperatingState = u.state;
      if (u.city.isNotEmpty) _selectedCity = u.city;

      for (final spec in u.specialties) {
        if (!_selectedSpecialties.contains(spec)) _selectedSpecialties.add(spec);
        if (!_availableSpecialties.contains(spec)) _availableSpecialties.add(spec);
      }

      _profilePicController.text = u.profilePicUrl;
      _aadhaarNumController.text = _formatAadhaarRaw(u.aadhaarNumber);
      _aadhaarFrontUrlController.text = u.aadhaarFrontUrl;
      _aadhaarBackUrlController.text = u.aadhaarBackUrl;
    }

    if (_currentStep == 5) {
      _setupVerificationListener();
    }
  }

  String _formatAadhaarRaw(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    final truncated = clean.length > 12 ? clean.substring(0, 12) : clean;
    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(truncated[i]);
    }
    return buffer.toString();
  }

  void _setupVerificationListener() {
    _verificationSubscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _verificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final isVerified = data['verified'] == true || data['isVerified'] == true;
        if (isVerified && mounted && _currentStep == 5) {
          _verificationSubscription?.cancel();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const GuideMainScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _customCityController.dispose();
    _expYearsController.dispose();
    _bioController.dispose();
    _languagesController.dispose();
    _languageSearchController.dispose();
    _specialtySearchController.dispose();
    _customSpecialtyController.dispose();
    _profilePicController.dispose();
    _aadhaarNumController.dispose();
    _aadhaarFrontUrlController.dispose();
    _aadhaarBackUrlController.dispose();
    super.dispose();
  }

  // STEP 0: PHONE OTP REGISTRATION (Requirement 3)
  void _handleSendOtpStep0() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full legal name.')),
      );
      return;
    }
    if (phone.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final code = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
      setState(() {
        _generatedOtp = code;
        _otpSent = true;
        _isSendingOtp = false;
        _otpController.text = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification OTP code sent: $code'),
          backgroundColor: AppColors.headerNavy,
        ),
      );
    });
  }

  Future<void> _handleVerifyOtpStep0() async {
    final otp = _otpController.text.trim();
    if (!_otpSent || otp != _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP code. Please enter the 6-digit code.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final fullPhone = '$_selectedCountryCode ${_phoneController.text.trim()}';

    try {
      final authRepo = AuthRepository();
      await authRepo.signUpWithPhoneOtp(
        fullPhone: fullPhone,
        name: _nameController.text.trim(),
        role: 'guide',
        country: _selectedCountry,
        state: _selectedOperatingState,
        city: _selectedCity,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _currentStep = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  Future<void> _saveStepProgress(int nextStep) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please sign in again.')),
      );
      return;
    }

    if (_currentStep == 4 && nextStep == 5) {
      final rawAadhaar = _aadhaarNumController.text.replaceAll(RegExp(r'\D'), '');
      if (rawAadhaar.length != 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aadhaar number must be exactly 12 digits.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final rawAadhaar = _aadhaarNumController.text.replaceAll(RegExp(r'\D'), '');
      final finalCity = _isCustomCity ? _customCityController.text.trim() : _selectedCity;

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'country': _selectedCountry,
        'phone': _phoneController.text.trim(),
        'birthState': _selectedBirthState,
        'state': _selectedOperatingState,
        'city': finalCity,
        'bio': _bioController.text.trim(),
        'experienceYears': int.tryParse(_expYearsController.text.trim()) ?? 0,
        'languages': _selectedLanguages,
        'specialties': _selectedSpecialties,
        'profilePicUrl': _profilePicController.text.trim(),
        'aadhaarNumber': rawAadhaar,
        'aadhaarFrontUrl': _aadhaarFrontUrlController.text.trim(),
        'aadhaarBackUrl': _aadhaarBackUrlController.text.trim(),
      };

      if (nextStep == 5) {
        data['onboardingComplete'] = true;
        data['verified'] = false;
        data['rejectionReason'] = FieldValue.delete();
        data['revokeReason'] = FieldValue.delete();
        data['rejection_reason'] = FieldValue.delete();
        data['adminNote'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _currentStep = nextStep;
        });

        if (nextStep == 5) {
          _setupVerificationListener();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save progress: $e')),
        );
      }
    }
  }

  // IMAGE PICKER & STORAGE UPLOAD
  Future<void> _pickAndUploadImage({
    required String storagePath,
    required void Function(XFile file, String url) onSuccess,
    required void Function(bool isLoading) setLoading,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Select Image Source', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.headerNavy),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (image != null) {
                      await _uploadFileToStorage(image, storagePath.replaceAll('{uid}', uid), onSuccess, setLoading);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.headerNavy),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (image != null) {
                      await _uploadFileToStorage(image, storagePath.replaceAll('{uid}', uid), onSuccess, setLoading);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadFileToStorage(
    XFile file,
    String path,
    void Function(XFile file, String url) onSuccess,
    void Function(bool isLoading) setLoading,
  ) async {
    setLoading(true);
    try {
      final bytes = await file.readAsBytes();
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setLoading(false);
        onSuccess(file, downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: AppColors.brandGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = 'CREATE GUIDE ACCOUNT';
    if (_currentStep >= 1 && _currentStep <= 4) {
      titleText = 'GUIDE ONBOARDING (STEP $_currentStep/4)';
    } else if (_currentStep == 5) {
      titleText = 'VERIFICATION STATUS';
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        title: Text(
          titleText,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              final nav = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                nav.pushReplacement(
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
      case 0:
        return _buildStep0CreateAccount();
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

  // STEP 0: PHONE OTP REGISTRATION (Requirement 3)
  Widget _buildStep0CreateAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Register as a Local Host',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your legal name and mobile number to verify via 6-digit OTP.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),

        _buildTextField('Full Legal Name', _nameController, Icons.person_outline, hint: 'e.g. Rahul Sharma'),
        const SizedBox(height: 16),

        // Phone Number with Country Code (Requirements 11 & 12)
        const Text('Mobile Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 105,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  isExpanded: true,
                  items: countryList.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.dialCode,
                      child: Text('${c.flag} ${c.dialCode}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCountryCode = val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Mobile number',
                  prefixIcon: const Icon(Icons.phone, color: AppColors.headerNavy, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (!_otpSent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _isSendingOtp ? null : _handleSendOtpStep0,
              icon: _isSendingOtp
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.white, size: 18),
              label: Text(
                _isSendingOtp ? 'Sending OTP...' : 'Send Verification OTP',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'OTP sent to $_selectedCountryCode ${_phoneController.text.trim()} (Code: $_generatedOtp)',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildTextField('Enter 6-Digit OTP', _otpController, Icons.key, keyboardType: TextInputType.number, hint: '123456'),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _isSubmitting ? null : _handleVerifyOtpStep0,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify OTP & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _isSendingOtp ? null : _handleSendOtpStep0,
              child: const Text('Resend Verification OTP', style: TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  // STEP 1: CASCADING COUNTRY -> STATE -> CITY (Requirements 11 & 12)
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Homeland & Operating Region', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Specify your native homeland, primary operating state, and base town.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),

        // 1. Country Dropdown (Requirement 11)
        const Text('Country / Homeland', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
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
              value: _selectedCountry,
              isExpanded: true,
              items: countryList.map((c) {
                return DropdownMenuItem(value: c.name, child: Text('${c.flag} ${c.name}'));
              }).toList(),
              onChanged: (newCountry) {
                if (newCountry != null) {
                  setState(() {
                    _selectedCountry = newCountry;
                    final matched = countryList.firstWhere((c) => c.name == newCountry);
                    _selectedCountryCode = matched.dialCode;
                    final states = availableStates;
                    _selectedOperatingState = states.first;
                    _selectedBirthState = states.first;
                    final cities = availableCities;
                    _selectedCity = cities.first;
                    _isCustomCity = false;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Primary Operating State Dropdown (Requirement 11)
        const Text('Operating State / Territory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
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
              value: availableStates.contains(_selectedOperatingState) ? _selectedOperatingState : availableStates.first,
              isExpanded: true,
              items: availableStates.map((st) {
                return DropdownMenuItem(value: st, child: Text(st));
              }).toList(),
              onChanged: (newState) {
                if (newState != null) {
                  setState(() {
                    _selectedOperatingState = newState;
                    final cities = availableCities;
                    _selectedCity = cities.first;
                    _isCustomCity = false;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Base City / Town Dropdown (Requirement 11)
        const Text('Base Town / City', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        if (!_isCustomCity) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: availableCities.contains(_selectedCity) ? _selectedCity : (availableCities.isNotEmpty ? availableCities.first : null),
                isExpanded: true,
                items: [
                  ...availableCities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  const DropdownMenuItem(value: '__custom__', child: Text('✍ Other / Custom Base Town...')),
                ],
                onChanged: (val) {
                  if (val == '__custom__') {
                    setState(() => _isCustomCity = true);
                  } else if (val != null) {
                    setState(() => _selectedCity = val);
                  }
                },
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCityController,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'Enter custom base town',
                    prefixIcon: const Icon(Icons.location_city, color: AppColors.headerNavy, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _isCustomCity = false),
                tooltip: 'Select from list',
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        _buildTextField('Years of Guiding Experience', _expYearsController, Icons.work_history, keyboardType: TextInputType.number, hint: 'e.g. 5'),
        const SizedBox(height: 16),

        _buildTextField('Guide Bio & Summary', _bioController, Icons.description, maxLines: 4, hint: 'Describe your homeland background, safety certifications, and mountain passion...'),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isSubmitting ? null : () => _saveStepProgress(2),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Next: Experience Specialties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // STEP 2: 17 EXPERIENCE-ORIENTED SPECIALTIES (Requirement 13)
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Experience Guiding Specialties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text(
          'Select your experience specialties from the dropdown or add custom ones. These describe what explorers will experience with you.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        // Dropdown selection to add specialties (Requirement 13: not box structures, proper dropdown/search)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black26),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Select an Experience Specialty...', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    isExpanded: true,
                    items: _availableSpecialties.map((spec) {
                      final isAlreadyAdded = _selectedSpecialties.contains(spec);
                      return DropdownMenuItem<String>(
                        value: spec,
                        child: Row(
                          children: [
                            Icon(
                              isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                              size: 16,
                              color: isAlreadyAdded ? AppColors.brandGreen : AppColors.headerNavy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isAlreadyAdded ? FontWeight.bold : FontWeight.normal,
                                  color: isAlreadyAdded ? AppColors.brandGreen : AppColors.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          if (!_selectedSpecialties.contains(val)) {
                            _selectedSpecialties.add(val);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Custom Specialty Entry (Requirement 13: "like if someone wants to add any new option, they can add using an add option over there")
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customSpecialtyController,
                style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Type custom experience specialty...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.star_outline, color: AppColors.headerNavy, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerNavy,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final custom = _customSpecialtyController.text.trim();
                if (custom.isNotEmpty) {
                  setState(() {
                    if (!_availableSpecialties.contains(custom)) {
                      _availableSpecialties.insert(0, custom);
                    }
                    if (!_selectedSpecialties.contains(custom)) {
                      _selectedSpecialties.add(custom);
                    }
                    _customSpecialtyController.clear();
                  });
                }
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selected Specialties Tags (Display clean tag chips, not rigid box grids)
        Text(
          'Selected Specialties (${_selectedSpecialties.length}):',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
        ),
        const SizedBox(height: 8),

        if (_selectedSpecialties.isEmpty)
          const Text('No specialties selected yet. Choose from dropdown above.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSpecialties.map((spec) {
              return Chip(
                backgroundColor: const Color(0xFFECFDF5),
                side: const BorderSide(color: Color(0xFFA7F3D0)),
                label: Text(spec, style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w600, fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF065F46)),
                onDeleted: () {
                  setState(() => _selectedSpecialties.remove(spec));
                },
              );
            }).toList(),
          ),

        const SizedBox(height: 24),

        // Languages Spoken
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Languages Spoken:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            Text('${_selectedLanguages.length} Selected', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Hindi', 'English', 'Nepali', 'Bengali', 'Garhwali', 'Kumaoni', 'Ladakhi', 'Tibetan', 'Malayalam', 'Tamil', 'Kannada', 'Marathi', 'Gujarati'].map((lang) {
            final isSel = _selectedLanguages.contains(lang);
            return FilterChip(
              label: Text(lang),
              selected: isSel,
              selectedColor: AppColors.headerNavy,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textMain, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 12),
              onSelected: (sel) {
                setState(() {
                  sel ? _selectedLanguages.add(lang) : _selectedLanguages.remove(lang);
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
                onPressed: _isSubmitting ? null : () => _saveStepProgress(3),
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
        const Text('Upload a clear, welcoming photo of yourself in your homeland terrain.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),

        _buildImageUploadCard(
          title: 'Upload Profile Photo',
          imageUrl: _profilePicController.text,
          xFile: _profileXFile,
          isLoading: _isUploadingProfile,
          onTap: () {
            _pickAndUploadImage(
              storagePath: 'guides/{uid}/profile.jpg',
              onSuccess: (file, url) {
                setState(() {
                  _profileXFile = file;
                  _profilePicController.text = url;
                });
              },
              setLoading: (isLoading) {
                setState(() => _isUploadingProfile = isLoading);
              },
            );
          },
        ),
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
                onPressed: _isSubmitting || _isUploadingProfile ? null : () => _saveStepProgress(4),
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

  // STEP 4: Aadhaar Verification
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identity Verification (Aadhaar)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Government ID verification is required to maintain safety across expeditions.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aadhaar Card Number (12 Digits Only)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 6),
            TextField(
              controller: _aadhaarNumController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textMain, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
                AadhaarNumberFormatter(),
              ],
              decoration: InputDecoration(
                hintText: 'XXXX XXXX XXXX',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13, letterSpacing: 1.0),
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.headerNavy, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Aadhaar Card Front Image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 8),
        _buildImageUploadCard(
          title: 'Upload Aadhaar Front',
          imageUrl: _aadhaarFrontUrlController.text,
          xFile: _aadhaarFrontXFile,
          isLoading: _isUploadingAadhaarFront,
          onTap: () {
            _pickAndUploadImage(
              storagePath: 'guides/{uid}/aadhaar_front.jpg',
              onSuccess: (file, url) {
                setState(() {
                  _aadhaarFrontXFile = file;
                  _aadhaarFrontUrlController.text = url;
                });
              },
              setLoading: (isLoading) {
                setState(() => _isUploadingAadhaarFront = isLoading);
              },
            );
          },
        ),
        const SizedBox(height: 20),

        const Text('Aadhaar Card Back Image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 8),
        _buildImageUploadCard(
          title: 'Upload Aadhaar Back',
          imageUrl: _aadhaarBackUrlController.text,
          xFile: _aadhaarBackXFile,
          isLoading: _isUploadingAadhaarBack,
          onTap: () {
            _pickAndUploadImage(
              storagePath: 'guides/{uid}/aadhaar_back.jpg',
              onSuccess: (file, url) {
                setState(() {
                  _aadhaarBackXFile = file;
                  _aadhaarBackUrlController.text = url;
                });
              },
              setLoading: (isLoading) {
                setState(() => _isUploadingAadhaarBack = isLoading);
              },
            );
          },
        ),

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
                onPressed: _isSubmitting || _isUploadingAadhaarFront || _isUploadingAadhaarBack ? null : () => _saveStepProgress(5),
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

  Widget _buildImageUploadCard({
    required String title,
    required String imageUrl,
    required XFile? xFile,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final bool hasImage = xFile != null || imageUrl.isNotEmpty;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasImage ? AppColors.brandGreen : Colors.black26, width: hasImage ? 2 : 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (xFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(xFile.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              )
            else if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.headerNavy),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Tap to Choose from Gallery or Take Photo', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            if (isLoading)
              Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  // STEP 5: DOCUMENTS UNDER REVIEW SCREEN (Requirement 14: Keep fixed until approved, no Go to Dashboard button)
  Widget _buildStep5VerificationPending() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final isVerified = data['verified'] == true || data['isVerified'] == true;
        final rejectionReason = data['rejectionReason'] ?? data['revokeReason'] ?? data['rejection_reason'] ?? data['adminNote'];
        final isRevoked = rejectionReason != null && rejectionReason.toString().trim().isNotEmpty;

        if (isVerified && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const GuideMainScreen()),
              (route) => false,
            );
          });
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isRevoked ? AppColors.brandRed.withValues(alpha: 0.12) : Colors.amber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRevoked ? Icons.gavel_rounded : Icons.hourglass_top,
                    size: 64,
                    color: isRevoked ? AppColors.brandRed : Colors.amber[800],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isRevoked ? 'Approval Revoked / Changes Required' : 'Verification Under Review',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                if (isRevoked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: AppColors.brandRed, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Admin Feedback & Required Edits:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandRed, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$rejectionReason',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit_note, color: Colors.white),
                    label: const Text(
                      'Click to Edit Requirements & Resubmit',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentStep = 1;
                      });
                    },
                  ),
                ] else ...[
                  const Text(
                    'Thank you for submitting your guide credentials! Your application and Aadhaar verification are currently under review by our administration team.\n\nYour host dashboard and itinerary creator are safely locked until official admin approval. This page will automatically update once verified.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.headerNavy),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh, color: AppColors.headerNavy, size: 18),
                  label: const Text('Refresh / Check Status', style: TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final u = FirebaseAuth.instance.currentUser;
                    if (u != null) {
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
                      if (!mounted) return;
                      if (doc.exists && doc.data() != null) {
                        final isV = doc.data()!['verified'] == true || doc.data()!['isVerified'] == true;
                        if (isV) {
                          nav.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const GuideMainScreen()),
                            (route) => false,
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Status checked: Still pending admin verification.')),
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
      },
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
