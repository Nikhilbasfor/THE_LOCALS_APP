import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/privacy_policy_dialog.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  String _selectedState = 'Uttarakhand';
  int _experienceYears = 2;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get isGuide => widget.role == 'guide';

  static const List<String> indianStates = [
    'Uttarakhand',
    'Himachal Pradesh',
    'Rajasthan',
    'Kerala',
    'Goa',
    'Jammu & Kashmir',
    'Sikkim',
    'Ladakh',
    'Karnataka',
    'Tamil Nadu',
    'Maharashtra',
    'Gujarat',
    'Uttar Pradesh',
    'West Bengal',
  ];

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepo.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        role: widget.role,
        phone: _phoneController.text,
        state: isGuide ? _selectedState : '',
        city: isGuide ? _cityController.text : '',
        experienceYears: isGuide ? _experienceYears : 0,
        bio: isGuide ? _bioController.text : '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully as ${widget.role.toUpperCase()}!'),
          backgroundColor: AppColors.brandGreen,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isGuide ? const GuideOnboardingScreen(initialStep: 1) : const TravellerMainScreen(),
        ),
        (route) => false,
      );
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
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isGuide ? AppColors.headerNavy : AppColors.travellerForestDark;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text('CREATE ${widget.role.toUpperCase()} ACCOUNT'),
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
                  isGuide ? 'Guide Registration' : 'Traveller Registration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill in details to register as a local ${widget.role}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusRevokedBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.brandRed, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  validator: (val) => (val == null || !val.contains('@')) ? 'Valid email required' : null,
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                  validator: (val) => (val == null || !RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) ? 'Enter a valid 10-digit mobile number' : null,
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.length < 6) ? 'At least 6 characters required' : null,
                ),
                const SizedBox(height: 14),

                // Guide-specific fields
                if (isGuide) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: const InputDecoration(labelText: 'Primary Operating State', prefixIcon: Icon(Icons.map_outlined), border: OutlineInputBorder()),
                    items: indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedState = val ?? _selectedState),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _cityController,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: const InputDecoration(labelText: 'City / Region', prefixIcon: Icon(Icons.location_city_outlined), border: OutlineInputBorder()),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'City required' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Text('Guiding Experience: ', style: TextStyle(color: AppColors.textMain, fontSize: 13)),
                      Text('$_experienceYears Years', style: const TextStyle(color: AppColors.headerNavy, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _experienceYears.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    activeColor: AppColors.headerNavy,
                    onChanged: (val) => setState(() => _experienceYears = val.toInt()),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: const InputDecoration(labelText: 'About / Guiding Bio', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Register as ${widget.role.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => PrivacyPolicyDialog.show(context),
                    child: Text(
                      'By registering, you agree to our Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColor.withValues(alpha: 0.8),
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
