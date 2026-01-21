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
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            _isOtpSent ? 'Verify OTP' : 'Welcome to BunkBite',
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            _isOtpSent
                ? 'Enter the 6- digit code sent to ${_emailController.text}'
                : 'Order food from your favourite canteen',
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Input Label (Welcome screen only)
          if (!_isOtpSent) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter your Email',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input Field
          TextField(
            controller: _isOtpSent ? _otpController : _emailController,
            keyboardType: _isOtpSent
                ? TextInputType.number
                : TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: _isOtpSent ? 'Enter otp' : 'you@example.com',
              hintStyle: GoogleFonts.urbanist(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),

          // Resend Link (Verify screen only)
          if (_isOtpSent) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: GoogleFonts.urbanist(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Resend logic
                    _handleSendOtp();
                  },
                  child: Text(
                    'Resend',
                    style: GoogleFonts.urbanist(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : (_isOtpSent ? _handleVerifyOtp : _handleSendOtp),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
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
