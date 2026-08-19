// lib/views/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_notification_controller.dart';
import 'package:stock_app/providers/auth_provider.dart';
import '../../../utils/constants.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onEditProfile;

  const ProfileScreen({super.key, required this.onEditProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // نجيب بيانات البروفايل الحقيقية من الـ Backend فور فتح الشاشة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
    });
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await context.read<DriverNotificationController>().unregisterDevice();
    if (!mounted) return;
    await authProvider.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen(role: '')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(height: screenHeight * 0.22, title: 'Account'),

          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildProfileCard(context, auth),
                    const SizedBox(height: 20),
                    _buildSettingsContainer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // صورة البروفايل (إن وُجدت) أو أيقونة افتراضية
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.beige,
            backgroundImage:
                (auth.profileImageUrl != null &&
                    auth.profileImageUrl!.isNotEmpty)
                ? NetworkImage(auth.profileImageUrl!)
                : null,
            child:
                (auth.profileImageUrl == null || auth.profileImageUrl!.isEmpty)
                ? const Icon(Icons.person, size: 36, color: AppColors.navy)
                : null,
          ),
          const SizedBox(height: 12),

          if (auth.isProfileLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            )
          else ...[
            Text(
              auth.profileFullName ?? '—',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // اسم المستخدم (لا يمكن تعديله — قيد من الباك اند)
            Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 10),
                Text(
                  auth.profileUserName ?? '—',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // رقم الهاتف
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 10),
                Text(
                  auth.profilePhoneNumber ?? '—',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onEditProfile,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.navy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "edit profile",
                style: TextStyle(color: AppColors.navy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
          ListTile(
            leading: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            title: const Text("Logout"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
    );
  }
}
