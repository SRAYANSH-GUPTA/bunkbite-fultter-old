import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'login_sheet.dart';
import 'owner/owner_main_view.dart';
import 'widgets/delete_account_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text(
                'Login to view profile',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const LoginSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF62F56),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login / Register'),
              ),
            ],
          ),
        ),
      );
    }

    final user = authState.user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Large Profile Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0x1AF62F56),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFFF62F56),
              ),
            ),

            const SizedBox(height: 40),

            // Admin Switch
            if (user.role == 'admin')
              ListTile(
                title: Text(
                  'Owner Dashboard',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                ),
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFFF62F56),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OwnerMainView()),
                  );
                },
                tileColor: const Color(0x0DF62F56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

            const SizedBox(height: 20),

            // Delete Account
            ListTile(
              title: Text(
                'Delete Account',
                style: GoogleFonts.urbanist(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.red,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => DeleteAccountDialog(
                    onConfirm: () async {
                      final success = await ref
                          .read(authProvider.notifier)
                          .deleteAccount();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Account deleted successfully',
                              style: GoogleFonts.urbanist(),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to delete account',
                              style: GoogleFonts.urbanist(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
              tileColor: const Color(0x0DF44336),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
