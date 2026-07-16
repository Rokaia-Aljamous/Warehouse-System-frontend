// lib/views/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // ---- تسجيل الخروج عبر AuthProvider (يستدعي الـ Backend أولاً ثم يمسح الجلسة) ----
  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (!mounted) return;

    // العودة إلى شاشة تسجيل الدخول مع مسح كامل الـ Stack.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(role: ''),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          // الهيدر الخاص بالبروفايل
          ReceivingTopHeader(height: screenHeight * 0.22, title: 'Account'),

          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -50), // لرفع الكارد ليغطي جزءاً من الهيدر
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildProfileCard(context),
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

  Widget _buildProfileCard(BuildContext context) {
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
          // الاسم
          const Text(
            "Ahmed Mohamed",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // البريد الإلكتروني مع الأيقونة
          Row(
            children: const [
              Icon(Icons.email_outlined, size: 20, color: Colors.black54),
              SizedBox(width: 10),
              Text(
                "aamell123@gmail.com",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // رقم الهاتف مع الأيقونة
          Row(
            children: const [
              Icon(Icons.phone_outlined, size: 20, color: Colors.black54),
              SizedBox(width: 10),
              Text("0944993829", style: TextStyle(color: Colors.black87)),
            ],
          ),

          const SizedBox(height: 20),

          // زر تعديل الملف الشخصي
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
          // ---- Logout tile: مربوط بـ AuthProvider.logout ----
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
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Delete Account",
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
