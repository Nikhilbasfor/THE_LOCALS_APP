import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/cinematic_scenic_background.dart';
import '../widgets/privacy_policy_dialog.dart';
import '../widgets/spring_interactions.dart';
import 'auth_screen.dart';
import 'guide/guide_main_screen.dart';
import 'guide/guide_onboarding_screen.dart';
import 'traveller/traveller_main_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role; // "traveller" or "guide"

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get isGuide => widget.role == 'guide';

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userModel = await _authRepo.login(
        email: _emailController.text,
        password: _passwordController.text,
        expectedRole: widget.role,
      );

      if (!mounted) return;

      if (widget.role == 'traveller') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TravellerMainScreen()),
          (route) => false,
        );
      } else {
        final currentUser = FirebaseAuth.instance.currentUser;
        final isEmailVerified = currentUser?.emailVerified ?? false;

        if (!userModel.onboardingComplete) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => GuideOnboardingScreen(
                initialUser: userModel,
                initialStep: isEmailVerified ? 1 : 0,
              ),
            ),
            (route) => false,
          );
        } else if (!userModel.verified) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => GuideOnboardingScreen(
                initialUser: userModel,
                initialStep: 5,
              ),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const GuideMainScreen()),
            (route) => false,
          );
        }
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

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;
    String? resetError;
    bool resetSuccess = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: isGuide ? const Color(0xFF059669) : const Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  const Text(
                    'Reset Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textMain),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your registered email address to receive a secure password reset link.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (resetError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      resetError!,
                      style: const TextStyle(color: AppColors.brandRed, fontSize: 12),
                    ),
                  ],
                  if (resetSuccess) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reset link sent! Please check your email inbox to reset your password.',
                              style: TextStyle(color: Color(0xFF065F46), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
                  child: Text(resetSuccess ? 'Done' : 'Cancel', style: const TextStyle(color: AppColors.textMuted)),
                ),
                if (!resetSuccess)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGuide ? const Color(0xFF059669) : const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isSending
                        ? null
                        : () async {
                            final email = resetEmailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              setModalState(() => resetError = 'Please enter a valid email address.');
                              return;
                            }
                            setModalState(() {
                              isSending = true;
                              resetError = null;
                            });
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                              setModalState(() {
                                isSending = false;
                                resetSuccess = true;
                              });
                            } catch (e) {
                              setModalState(() {
                                isSending = false;
                                resetError = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    child: isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isGuide ? const Color(0xFF34D399) : const Color(0xFF38BDF8);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Text(
            '${widget.role.toUpperCase()} PORTAL',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: CinematicScenicBackground(
        imageUrl: isGuide
            ? 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1600&q=85'
            : 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1600&q=85',
        overlayAlpha: 0.65,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: bespokeBouncingScrollPhysics,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFF0F172A).withValues(alpha: 0.72),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Icon
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                isGuide ? Icons.nature_people : Icons.backpack,
                                color: accentColor,
                                size: 32,
                              ),
                            ),
                          ).springPop(delayMs: 100),
                          const SizedBox(height: 14),

                          Text(
                            isGuide ? 'Guide Sign In' : 'Traveller Sign In',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isGuide
                                ? 'Welcome back! Sign in to host expeditions'
                                : 'Welcome back! Sign in to continue your adventure',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error notification banner if any
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.brandRed.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email Input Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                              prefixIcon: Icon(Icons.email_outlined, color: accentColor, size: 20),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: accentColor, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Please enter your email';
                              if (!val.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Input Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                              prefixIcon: Icon(Icons.lock_outline, color: accentColor, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: accentColor, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Please enter your password';
                              if (val.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Bouncing Sign In Button
                          BouncingButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            isLoading: _isLoading,
                            backgroundColor: isGuide
                                ? const Color(0xFF059669)
                                : const Color(0xFF0284C7),
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Sign In as ${widget.role.toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (isGuide) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const GuideOnboardingScreen(initialStep: 0),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AuthScreen(role: widget.role),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => PrivacyPolicyDialog.show(context),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
