import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import 'guide_main_screen.dart';
import '../role_selection_screen.dart';

const List<String> allStatesAndUTs = [
  'Nepal',
  'Bhutan',
  'Tibet',
  'Himachal Pradesh',
  'Uttarakhand',
  'Jammu and Kashmir',
  'Ladakh',
  'Sikkim',
  'Arunachal Pradesh',
  'Assam',
  'Meghalaya',
  'Nagaland',
  'Manipur',
  'Mizoram',
  'Tripura',
  'West Bengal',
  'Andhra Pradesh',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Tamil Nadu',
  'Telangana',
  'Uttar Pradesh',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi (NCT)',
  'Lakshadweep',
  'Puducherry',
];

const Map<String, List<String>> stateCitiesMap = {
  'Nepal': ['Kathmandu', 'Pokhara', 'Lalitpur', 'Bharatpur', 'Lukla', 'Namche Bazaar', 'Chitwan', 'Nagarkot'],
  'Bhutan': ['Thimphu', 'Paro', 'Punakha', 'Phuentsholing', 'Jakhar', 'Wangdue Phodrang'],
  'Tibet': ['Lhasa', 'Shigatse', 'Gyantse', 'Chamdo', 'Nyingchi', 'Tingri'],
  'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Tirupati', 'Rajahmundry', 'Kakinada', 'Anantapur', 'Eluru'],
  'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro', 'Bomdila', 'Tezu', 'Changlang'],
  'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon', 'Tinsukia', 'Tezpur', 'Bongaigaon'],
  'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia', 'Darbhanga', 'Bihar Sharif', 'Arrah'],
  'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Rajnandgaon', 'Jagdalpur', 'Ambikapur'],
  'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda'],
  'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Gandhinagar', 'Kutch'],
  'Haryana': ['Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal'],
  'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Kullu', 'Mandi', 'Solan', 'Chamba', 'Dalhousie', 'Spiti', 'Kasol'],
  'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh', 'Deoghar', 'Giridih'],
  'Karnataka': ['Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi', 'Davangere', 'Ballari', 'Shivamogga', 'Coorg'],
  'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Kollam', 'Thrissur', 'Kannur', 'Alappuzha', 'Munnar', 'Wayanad'],
  'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas', 'Satna', 'Khajuraho'],
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Chhatrapati Sambhajinagar', 'Solapur', 'Amravati', 'Kolhapur'],
  'Manipur': ['Imphal', 'Churachandpur', 'Thoubal', 'Bishnupur', 'Ukhrul'],
  'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Nongpoh', 'Cherrapunji'],
  'Mizoram': ['Aizawl', 'Lunglei', 'Saiha', 'Champhai'],
  'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha'],
  'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur', 'Puri', 'Balasore'],
  'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Pathankot'],
  'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer', 'Jaisalmer', 'Pushkar', 'Bharatpur'],
  'Sikkim': ['Gangtok', 'Namchi', 'Geyzing', 'Mangan', 'Pelling', 'Lachung'],
  'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Erode', 'Vellore', 'Ooty', 'Kodaikanal'],
  'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam', 'Ramagundam'],
  'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailashahar'],
  'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi', 'Agra', 'Noida', 'Prayagraj', 'Ghaziabad', 'Meerut', 'Gorakhpur', 'Mathura'],
  'Uttarakhand': ['Dehradun', 'Haridwar', 'Rishikesh', 'Nainital', 'Mussoorie', 'Haldwani', 'Roorkee', 'Almora', 'Kedarnath', 'Badrinath'],
  'West Bengal': ['Kolkata', 'Howrah', 'Darjeeling', 'Siliguri', 'Asansol', 'Durgapur', 'Kalimpong', 'Digha'],
  'Andaman and Nicobar Islands': ['Port Blair', 'Havelock Island', 'Neil Island', 'Diglipur'],
  'Chandigarh': ['Chandigarh'],
  'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa'],
  'Delhi (NCT)': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi', 'Central Delhi'],
  'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Gulmarg', 'Pahalgam', 'Katras'],
  'Ladakh': ['Leh', 'Kargil', 'Nubra Valley', 'Zanskar', 'Pangong'],
  'Lakshadweep': ['Kavaratti', 'Agatti', 'Amini', 'Andrott'],
  'Puducherry': ['Puducherry', 'Karaikal', 'Mahe', 'Yanam'],
};

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
  bool _emailVerificationSent = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _verificationSubscription;

  // Step 0 Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 1 Controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedBirthState = 'Himachal Pradesh';
  String _selectedOperatingState = 'Himachal Pradesh';
  String _selectedCity = 'Shimla';
  final _expYearsController = TextEditingController();
  final _bioController = TextEditingController();

  // Step 2 Selection Lists & Controllers
  final _languagesController = TextEditingController();
  final List<String> _allLanguages = ['Hindi', 'English'];
  final List<String> _selectedLanguages = ['Hindi', 'English'];
  final _languageSearchController = TextEditingController();
  String _languageSearchQuery = '';

  final List<String> _allRegions = ['Himachal Pradesh', 'Uttarakhand', 'Ladakh', 'Sikkim'];
  final List<String> _selectedRegions = ['Himachal Pradesh'];
  final _regionSearchController = TextEditingController();
  String _regionSearchQuery = '';

  final List<String> _allSpecialties = [
    "Trekking",
    "Cultural Tours",
    "Wildlife Safari",
    "Photography Tours"
  ];
  final List<String> _selectedSpecialties = ["Trekking"];
  final _specialtySearchController = TextEditingController();
  String _specialtySearchQuery = '';

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

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _emailController.text = currentUser.email ?? '';
      _nameController.text = currentUser.displayName ?? '';
      if (currentUser.emailVerified) {
        _emailVerificationSent = true;
      }
    }

    if (widget.initialUser != null) {
      final u = widget.initialUser!;
      if (u.name.isNotEmpty) _nameController.text = u.name;
      if (u.email.isNotEmpty) _emailController.text = u.email;
      _phoneController.text = u.phone;
      _bioController.text = u.bio;
      for (final lang in u.languages) {
        if (!_selectedLanguages.contains(lang)) _selectedLanguages.add(lang);
        if (!_allLanguages.contains(lang)) _allLanguages.add(lang);
      }
      _languagesController.text = _selectedLanguages.join(', ');
      _expYearsController.text = u.experienceYears > 0 ? '${u.experienceYears}' : '';
      if (u.birthState.isNotEmpty) _selectedBirthState = u.birthState;
      if (u.state.isNotEmpty) _selectedOperatingState = u.state;
      if (u.city.isNotEmpty) _selectedCity = u.city;
      for (final reg in u.regions) {
        if (!_selectedRegions.contains(reg)) _selectedRegions.add(reg);
        if (!_allRegions.contains(reg)) _allRegions.add(reg);
      }
      
      for (final spec in u.specialties) {
        if (!_selectedSpecialties.contains(spec)) {
          _selectedSpecialties.add(spec);
        }
        if (!_allSpecialties.contains(spec)) {
          _allSpecialties.add(spec);
        }
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
        final isVerified = data['verified'] ?? data['isVerified'] ?? false;
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
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _expYearsController.dispose();
    _bioController.dispose();
    _languagesController.dispose();
    _specialtySearchController.dispose();
    _profilePicController.dispose();
    _aadhaarNumController.dispose();
    _aadhaarFrontUrlController.dispose();
    _aadhaarBackUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitStep0CreateAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: 'GuideTemp#${DateTime.now().millisecondsSinceEpoch % 100000}!',
        );
        user = cred.user;
      }

      if (user != null) {
        await user.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'guide',
          'onboardingComplete': false,
          'verified': false,
        }, SetOptions(merge: true));

        await user.sendEmailVerification();

        if (mounted) {
          setState(() {
            _emailVerificationSent = true;
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification link sent to $email. Please verify then continue.'),
              backgroundColor: AppColors.headerNavy,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification link: $e')),
        );
      }
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        if (updatedUser?.emailVerified == true) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _currentStep = 1;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email is not verified yet. Please check your inbox and click the verification link."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking verification status: $e')),
        );
      }
    }
  }

  Future<void> _saveStepProgress(int nextStep) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_currentStep == 1) {
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password must be at least 6 characters.')),
          );
          return;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match.')),
          );
          return;
        }
      }
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
      if (_currentStep == 1 && _passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      final rawAadhaar = _aadhaarNumController.text.replaceAll(RegExp(r'\D'), '');

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birthState': _selectedBirthState,
        'state': _selectedOperatingState,
        'city': _selectedCity,
        'bio': _bioController.text.trim(),
        'experienceYears': int.tryParse(_expYearsController.text.trim()) ?? 0,
        'languages': _languagesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'regions': _selectedRegions,
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

  // IMAGE PICKER & FIREBASE STORAGE UPLOAD HELPER
  Future<void> _pickAndUploadImage({
    required String storagePath,
    required void Function(XFile file, String url) onSuccess,
    required void Function(bool isLoading) setLoading,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session not found. Please log in again.')),
      );
      return;
    }

    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerNavy),
                ),
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
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: AppColors.brandGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showSearchableStatePicker(BuildContext context, String currentSelection, String title) async {
    String searchQuery = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredStates = allStatesAndUTs
                .where((s) => s.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerNavy),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'Search State or Union Territory...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.headerNavy),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredStates.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final stateName = filteredStates[index];
                        final isSelected = stateName == currentSelection;
                        return ListTile(
                          title: Text(
                            stateName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.headerNavy : AppColors.textMain,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.headerNavy) : null,
                          onTap: () {
                            Navigator.of(context).pop(stateName);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showSearchableCityPicker(BuildContext context, String currentState, String currentCity) async {
    String searchQuery = '';
    final defaultCities = stateCitiesMap[currentState] ?? ['Main City / Town'];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCities = defaultCities
                .where((c) => c.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            final cleanQuery = searchQuery.trim();
            final bool canAddCustom = cleanQuery.isNotEmpty &&
                !defaultCities.any((c) => c.toLowerCase() == cleanQuery.toLowerCase());

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Select City / Town ($currentState)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerNavy),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'Search city or type custom city name...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.headerNavy),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (canAddCustom) ...[
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: AppColors.brandGreen),
                      title: Text(
                        'Add "$cleanQuery"',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandGreen),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(cleanQuery);
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredCities.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cityName = filteredCities[index];
                        final isSelected = cityName == currentCity;
                        return ListTile(
                          title: Text(
                            cityName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.headerNavy : AppColors.textMain,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.headerNavy) : null,
                          onTap: () {
                            Navigator.of(context).pop(cityName);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  // STEP 0: Create Guide Account & Email Verification
  Widget _buildStep0CreateAccount() {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Guide Account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your basic credentials to begin registration as a local guide.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        _buildTextField('Full Name', _nameController, Icons.person_outline, hint: 'e.g. Rahul Sharma'),
        const SizedBox(height: 16),
        _buildTextField('Email Address', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress, hint: 'e.g. rahul@example.com'),
        const SizedBox(height: 24),

        if (!_emailVerificationSent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _isSubmitting ? null : _submitStep0CreateAccount,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Account & Send Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            ),
          ),
        ],

        if (_emailVerificationSent) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.headerNavy),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.mark_email_read, color: AppColors.headerNavy, size: 24),
                    SizedBox(width: 10),
                    Text('Email Verification Sent', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headerNavy)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Verification link sent to $email. Please verify then continue.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("I've Verified", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              onPressed: _isSubmitting ? null : _checkEmailVerified,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : _submitStep0CreateAccount,
              child: const Text('Resend Verification Email', style: TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  // STEP 1: Phone, Password, Operating State, City, Region, Exp, Bio
  Widget _buildStep1() {
    final cities = stateCitiesMap[_selectedOperatingState] ?? ['Capital / Main City'];
    if (!cities.contains(_selectedCity)) {
      _selectedCity = cities.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal & Professional Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Provide your contact details, operating location, and experience.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),

        _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone, hint: '+91 9876543210'),
        const SizedBox(height: 16),

        // Password & Confirm Password
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.headerNavy, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.headerNavy),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Re-enter password',
                prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.headerNavy, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.headerNavy),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Birth State / Country / Region
        const Text('Native State / Country / Region', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await _showSearchableStatePicker(context, _selectedBirthState, 'Select State / Country / Region');
            if (picked != null) {
              setState(() => _selectedBirthState = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake, color: AppColors.headerNavy, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthState,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.headerNavy),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Primary Operating State / Country / Region (Searchable Dropdown)
        const Text('Primary Operating State / Country / Region', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await _showSearchableStatePicker(context, _selectedOperatingState, 'Select Operating State / Region');
            if (picked != null && picked != _selectedOperatingState) {
              setState(() {
                _selectedOperatingState = picked;
                final newCities = stateCitiesMap[picked] ?? ['Capital / Main City'];
                _selectedCity = newCities.first;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.headerNavy, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedOperatingState,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.headerNavy),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // City / Town (Searchable Picker with Custom City Entry)
        const Text('City / Town', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await _showSearchableCityPicker(context, _selectedOperatingState, _selectedCity);
            if (picked != null && picked.isNotEmpty) {
              setState(() => _selectedCity = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_city, color: AppColors.headerNavy, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCity,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.headerNavy),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildTextField('Years of Guiding Experience', _expYearsController, Icons.work_history, keyboardType: TextInputType.number, hint: 'e.g. 5'),
        const SizedBox(height: 16),

        _buildTextField('Guide Bio & Summary', _bioController, Icons.description, maxLines: 4, hint: 'Describe your expertise in trekking, local culture, and mountain safety...'),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerNavy, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isSubmitting ? null : () => _saveStepProgress(2),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Next: Regional Expertise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // STEP 2: Languages, Regions & Specialties Chips (4 presets each + search & add custom)
  Widget _buildStep2() {
    const forestGreen = Color(0xFF0D3B2E);

    // Filtered lists
    final filteredLanguages = _allLanguages.where((l) => l.toLowerCase().contains(_languageSearchQuery.toLowerCase())).toList();
    final cleanLangQuery = _languageSearchQuery.trim();
    final bool canAddLang = cleanLangQuery.isNotEmpty &&
        !_allLanguages.any((l) => l.toLowerCase() == cleanLangQuery.toLowerCase()) &&
        !_selectedLanguages.any((l) => l.toLowerCase() == cleanLangQuery.toLowerCase());

    final filteredRegions = _allRegions.where((r) => r.toLowerCase().contains(_regionSearchQuery.toLowerCase())).toList();
    final cleanRegionQuery = _regionSearchQuery.trim();
    final bool canAddRegion = cleanRegionQuery.isNotEmpty &&
        !_allRegions.any((r) => r.toLowerCase() == cleanRegionQuery.toLowerCase()) &&
        !_selectedRegions.any((r) => r.toLowerCase() == cleanRegionQuery.toLowerCase());

    final filteredSpecialties = _allSpecialties.where((s) => s.toLowerCase().contains(_specialtySearchQuery.toLowerCase())).toList();
    final cleanSpecQuery = _specialtySearchQuery.trim();
    final bool canAddSpec = cleanSpecQuery.isNotEmpty &&
        !_allSpecialties.any((s) => s.toLowerCase() == cleanSpecQuery.toLowerCase()) &&
        !_selectedSpecialties.any((s) => s.toLowerCase() == cleanSpecQuery.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Regional Expertise & Specialties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Select your languages, guiding regions, and core tour specialties.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),

        // 1. LANGUAGES SPOKEN
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Languages Spoken:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            Text('${_selectedLanguages.length} Selected', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: forestGreen)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _languageSearchController,
          style: const TextStyle(color: AppColors.textMain, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search or add language...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            prefixIcon: const Icon(Icons.translate, color: AppColors.headerNavy, size: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
          ),
          onChanged: (val) => setState(() => _languageSearchQuery = val),
        ),
        const SizedBox(height: 8),
        if (canAddLang)
          GestureDetector(
            onTap: () {
              setState(() {
                _allLanguages.insert(0, cleanLangQuery);
                _selectedLanguages.add(cleanLangQuery);
                _languageSearchController.clear();
                _languageSearchQuery = '';
                _languagesController.text = _selectedLanguages.join(', ');
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: AppColors.headerNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.headerNavy)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_circle, color: AppColors.headerNavy, size: 16),
                const SizedBox(width: 4),
                Text('Add "$cleanLangQuery"', style: const TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredLanguages.map((lang) {
            final isSel = _selectedLanguages.contains(lang);
            return RawChip(
              label: Text(lang),
              selected: isSel,
              showCheckmark: isSel,
              checkmarkColor: Colors.white,
              selectedColor: AppColors.headerNavy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textMain, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? AppColors.headerNavy : Colors.black26)),
              onSelected: (sel) {
                setState(() {
                  sel ? _selectedLanguages.add(lang) : _selectedLanguages.remove(lang);
                  _languagesController.text = _selectedLanguages.join(', ');
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 2. REGIONS YOU GUIDE IN
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Regions You Guide In:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            Text('${_selectedRegions.length} Selected', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: forestGreen)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _regionSearchController,
          style: const TextStyle(color: AppColors.textMain, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search or add region...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            prefixIcon: const Icon(Icons.map_outlined, color: AppColors.headerNavy, size: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
          ),
          onChanged: (val) => setState(() => _regionSearchQuery = val),
        ),
        const SizedBox(height: 8),
        if (canAddRegion)
          GestureDetector(
            onTap: () {
              setState(() {
                _allRegions.insert(0, cleanRegionQuery);
                _selectedRegions.add(cleanRegionQuery);
                _regionSearchController.clear();
                _regionSearchQuery = '';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: AppColors.headerNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.headerNavy)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_circle, color: AppColors.headerNavy, size: 16),
                const SizedBox(width: 4),
                Text('Add "$cleanRegionQuery"', style: const TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredRegions.map((reg) {
            final isSel = _selectedRegions.contains(reg);
            return RawChip(
              label: Text(reg),
              selected: isSel,
              showCheckmark: isSel,
              checkmarkColor: Colors.white,
              selectedColor: AppColors.headerNavy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textMain, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? AppColors.headerNavy : Colors.black26)),
              onSelected: (sel) {
                setState(() {
                  sel ? _selectedRegions.add(reg) : _selectedRegions.remove(reg);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 3. GUIDING SPECIALTIES
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Guiding Specialties:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
            Text('${_selectedSpecialties.length} Selected', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: forestGreen)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _specialtySearchController,
          style: const TextStyle(color: AppColors.textMain, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search or add specialty...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            prefixIcon: const Icon(Icons.star_outline, color: forestGreen, size: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
          ),
          onChanged: (val) => setState(() => _specialtySearchQuery = val),
        ),
        const SizedBox(height: 8),
        if (canAddSpec)
          GestureDetector(
            onTap: () {
              setState(() {
                _allSpecialties.insert(0, cleanSpecQuery);
                _selectedSpecialties.add(cleanSpecQuery);
                _specialtySearchController.clear();
                _specialtySearchQuery = '';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: forestGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: forestGreen)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_circle, color: forestGreen, size: 16),
                const SizedBox(width: 4),
                Text('Add "$cleanSpecQuery"', style: const TextStyle(color: forestGreen, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredSpecialties.map((spec) {
            final isSel = _selectedSpecialties.contains(spec);
            return RawChip(
              label: Text(spec),
              selected: isSel,
              showCheckmark: isSel,
              checkmarkColor: Colors.white,
              selectedColor: forestGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textMain, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? forestGreen : Colors.black26)),
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

  // STEP 3: Profile Photo with Camera / Gallery Picker & Storage Upload
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Upload a clear headshot image for your guide badge (Gallery or Camera).', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),

        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: AppColors.headerNavy, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: ClipOval(
                  child: _profileXFile != null
                      ? Image.file(File(_profileXFile!.path), fit: BoxFit.cover, width: 120, height: 120)
                      : (_profilePicController.text.isNotEmpty
                          ? Image.network(
                              _profilePicController.text,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60, color: AppColors.headerNavy),
                            )
                          : const Icon(Icons.person, size: 60, color: AppColors.headerNavy)),
                ),
              ),
              if (_isUploadingProfile)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerNavy,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            label: Text(
              _profilePicController.text.isNotEmpty || _profileXFile != null ? 'Change Profile Photo' : 'Upload Profile Photo',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _isUploadingProfile
                ? null
                : () {
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
        ),
        const SizedBox(height: 24),

        _buildTextField('Profile Picture Image URL (Auto-filled on upload)', _profilePicController, Icons.image, hint: 'https://...', onChanged: (_) => setState(() {})),
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

  // STEP 4: Aadhaar Identity Verification Upload with Gallery & Camera options
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identity Verification (Aadhaar)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 6),
        const Text('Government ID verification is required to maintain safety across expeditions.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),

        // Aadhaar Number with 12-digit Visual Transformation
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
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Aadhaar Front Image Box
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

        // Aadhaar Back Image Box
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
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                    'Thank you for completing your guide profile! Our admin team is verifying your credentials. You will be automatically redirected once approved.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.headerNavy),
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
                            const SnackBar(content: Text('Status checked. Awaiting admin approval.')),
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
