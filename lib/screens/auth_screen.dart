import 'package:flutter/material.dart';
import '../data/geo_data.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/privacy_policy_dialog.dart';
import '../widgets/spring_interactions.dart';
import 'guide/guide_onboarding_screen.dart';
import 'traveller/traveller_main_screen.dart';

class AuthScreen extends StatefulWidget {
  final String role; // "traveller" or "guide"

  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  String _selectedCountry = 'India';
  String _selectedCountryCode = '+91';
  String _selectedState = 'Uttarakhand';
  String _selectedCity = 'Dehradun';
  bool _isCustomCity = false;

  int _experienceYears = 2;
  bool _isLoading = false;
  String? _errorMessage;

  bool _otpSent = false;
  String _generatedOtp = '';
  bool _isSendingOtp = false;

  bool get isGuide => widget.role == 'guide';

  List<String> get availableStates {
    if (_selectedCountry == 'India') return indianStatesAndUTs;
    if (_selectedCountry == 'Nepal') return nepalRegions;
    if (_selectedCountry == 'Bhutan') return bhutanRegions;
    return ['All Regions'];
  }

  List<String> get availableCities {
    return stateCitiesMap[_selectedState] ?? ['Base Town'];
  }

  void _onCountryChanged(String? newCountry) {
    if (newCountry == null) return;
    setState(() {
      _selectedCountry = newCountry;
      final matchedCountry = countryList.firstWhere(
        (c) => c.name == newCountry,
        orElse: () => const CountryInfo(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
      );
      _selectedCountryCode = matchedCountry.dialCode;

      final states = availableStates;
      _selectedState = states.isNotEmpty ? states.first : 'Default';
      final cities = availableCities;
      _selectedCity = cities.isNotEmpty ? cities.first : 'Default';
      _isCustomCity = false;
    });
  }

  void _onStateChanged(String? newState) {
    if (newState == null) return;
    setState(() {
      _selectedState = newState;
      final cities = availableCities;
      _selectedCity = cities.isNotEmpty ? cities.first : 'Default';
      _isCustomCity = false;
    });
  }

  void _handleSendOtp() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 2) {
      setState(() => _errorMessage = 'Please provide your full legal name.');
      return;
    }
    if (phone.length < 6) {
      setState(() => _errorMessage = 'Please enter a valid mobile number.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSendingOtp = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final code = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
      setState(() {
        _generatedOtp = code;
        _otpSent = true;
        _isSendingOtp = false;
        _otpController.text = code;
      });
    });
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (!_otpSent || otp != _generatedOtp) {
      setState(() => _errorMessage = 'Invalid OTP code. Please enter the 6-digit code sent to your phone.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullPhone = '$_selectedCountryCode $phone';
    final finalCity = _isCustomCity ? _cityController.text.trim() : _selectedCity;

    try {
      final user = await _authRepo.signUpWithPhoneOtp(
        fullPhone: fullPhone,
        name: _nameController.text.trim(),
        role: widget.role,
        country: _selectedCountry,
        state: _selectedState,
        city: finalCity,
        experienceYears: isGuide ? _experienceYears : 0,
        bio: isGuide ? _bioController.text.trim() : '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account verified & created successfully as ${widget.role.toUpperCase()}!'),
          backgroundColor: AppColors.brandGreen,
        ),
      );

      if (isGuide) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => GuideOnboardingScreen(
              initialUser: user,
              initialStep: 1,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TravellerMainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isGuide ? AppColors.headerNavy : AppColors.travellerForestDark;
    final accentColor = isGuide ? const Color(0xFF059669) : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
          'CREATE ${widget.role.toUpperCase()} ACCOUNT',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isGuide ? 'Guide / Host Registration' : 'Traveller Registration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill in your details to register with mobile OTP verification',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.brandRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.brandRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Legal Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Legal Name',
                    prefixIcon: Icon(Icons.person, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your full legal name' : null,
                ),
                const SizedBox(height: 16),

                // Country Picker Dropdown (Requirement 11)
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Country / Homeland',
                    prefixIcon: Icon(Icons.public, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: countryList.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.name,
                      child: Text('${c.flag} ${c.name}'),
                    );
                  }).toList(),
                  onChanged: _onCountryChanged,
                ),
                const SizedBox(height: 16),

                // Phone Number with Country Code (Requirement 12)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 105,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          isExpanded: true,
                          items: countryList.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.dialCode,
                              child: Text(
                                '${c.flag} ${c.dialCode}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Icons.phone, color: accentColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid mobile number' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // State / Region Cascading Dropdown (Requirement 11)
                DropdownButtonFormField<String>(
                  value: availableStates.contains(_selectedState) ? _selectedState : (availableStates.isNotEmpty ? availableStates.first : null),
                  decoration: InputDecoration(
                    labelText: 'State / Territory',
                    prefixIcon: Icon(Icons.map, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: availableStates.map((st) {
                    return DropdownMenuItem<String>(
                      value: st,
                      child: Text(st),
                    );
                  }).toList(),
                  onChanged: _onStateChanged,
                ),
                const SizedBox(height: 16),

                // City / Base Town Cascading Dropdown (Requirement 11)
                if (!_isCustomCity) ...[
                  DropdownButtonFormField<String>(
                    value: availableCities.contains(_selectedCity) ? _selectedCity : (availableCities.isNotEmpty ? availableCities.first : null),
                    decoration: InputDecoration(
                      labelText: 'City / Base Town',
                      prefixIcon: Icon(Icons.location_city, color: accentColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      ...availableCities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                      const DropdownMenuItem<String>(value: '__other__', child: Text('✍ Other / Custom Town...')),
                    ],
                    onChanged: (val) {
                      if (val == '__other__') {
                        setState(() => _isCustomCity = true);
                      } else if (val != null) {
                        setState(() => _selectedCity = val);
                      }
                    },
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'Custom City / Base Town',
                            prefixIcon: Icon(Icons.location_city, color: accentColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your city/town' : null,
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

                if (isGuide) ...[
                  Row(
                    children: [
                      const Text('Guiding Experience (years):', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _experienceYears.toDouble(),
                          min: 0,
                          max: 30,
                          divisions: 30,
                          label: '$_experienceYears yrs',
                          activeColor: AppColors.brandGreen,
                          onChanged: (v) => setState(() => _experienceYears = v.toInt()),
                        ),
                      ),
                      Text('$_experienceYears yrs', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bioController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Short Bio / Passion for Guiding',
                      prefixIcon: Icon(Icons.description, color: accentColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // OTP Verification Flow (Requirement 3)
                if (!_otpSent) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSendingOtp ? null : _handleSendOtp,
                    icon: _isSendingOtp
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _isSendingOtp ? 'Sending OTP...' : 'Send Verification OTP',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'OTP Sent to $_selectedCountryCode ${_phoneController.text.trim()} (Code: $_generatedOtp)',
                            style: const TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Enter 6-Digit OTP',
                      prefixIcon: Icon(Icons.key, color: accentColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  BouncingButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    isLoading: _isLoading,
                    backgroundColor: themeColor,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Verify & Create ${widget.role.toUpperCase()} Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () => PrivacyPolicyDialog.show(context),
                    child: const Text(
                      'Privacy Policy & Terms of Service',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
