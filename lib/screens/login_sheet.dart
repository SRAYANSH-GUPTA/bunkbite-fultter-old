import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'owner/owner_main_view.dart';

class LoginSheet extends ConsumerStatefulWidget {
  const LoginSheet({super.key});

  @override
  ConsumerState<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<LoginSheet> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    // Hardcore email validation regex based on RFC 5322
    // This regex validates:
    // - Local part: alphanumeric, dots, hyphens, underscores, plus signs
    // - No consecutive dots or dots at start/end of local part
    // - Domain: alphanumeric with hyphens, proper subdomain structure
    // - TLD: 2-63 characters, letters only
    // - No leading/trailing dots or hyphens in domain parts
    final emailRegex = RegExp(
      r'^(?!.*\.\.)(?!\.)[a-zA-Z0-9]+(?:[._+-][a-zA-Z0-9]+)*@'
      r'(?!-)[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*'
      r'(?:\.[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*)*'
      r'\.[a-zA-Z]{2,63}$',
      caseSensitive: false,
    );

    // Additional validation checks
    if (email.isEmpty || email.length > 254) return false;
    if (!emailRegex.hasMatch(email)) return false;

    // Check local part length (before @)
    final parts = email.split('@');
    if (parts.length != 2) return false;
    if (parts[0].isEmpty || parts[0].length > 64) return false;

    // Ensure domain has at least one dot and valid structure
    final domain = parts[1];
    if (!domain.contains('.')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    if (domain.startsWith('-') || domain.endsWith('-')) return false;

    // Check for invalid consecutive characters
    if (email.contains('..') ||
        email.contains('--') ||
        email.contains('.-') ||
        email.contains('-.')) {
      return false;
    }

    return true;
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();

    // Check if email is empty
    if (email.isEmpty) {
      _showErrorToast('Please enter your email address');
      return;
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      _showErrorToast('Please enter a valid email address');
      return;
    }

    final success = await ref.read(authProvider.notifier).sendOtp(email);
    if (success && mounted) {
      setState(() {
        _isOtpSent = true;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (email.isEmpty || otp.isEmpty) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(email, otp);
    if (success && mounted) {
      Navigator.pop(context); // Close sheet

      // Check if Admin
      final user = ref.read(authProvider).user;
      if (user?.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerMainView()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth errors and show them as toasts
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        _showErrorToast(next.error!);
      }
    });

    final authState = ref.watch(authProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isOtpSent ? 'Verify OTP' : 'Login / Register',
            style: GoogleFonts.urbanist(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isOtpSent
                ? 'Enter the 6-digit code sent to ${_emailController.text}'
                : 'Enter your email to continue',
            style: GoogleFonts.urbanist(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          if (!_isOtpSent)
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email Address',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            )
          else
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : (_isOtpSent ? _handleVerifyOtp : _handleSendOtp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF62F56),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isOtpSent ? 'Verify & Login' : 'Send OTP',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
