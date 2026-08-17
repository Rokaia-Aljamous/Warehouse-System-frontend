import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/providers/auth_provider.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/screens/common/login_screen.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';

class DriverProfileScreen extends StatefulWidget {
  final VoidCallback onEditProfile;

  const DriverProfileScreen({super.key, required this.onEditProfile});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen(role: '')),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverController>();
    final profile = controller.profile;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(
            height: MediaQuery.of(context).size.height * 0.22,
            title: 'Driver Profile',
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -45),
              child: RefreshIndicator(
                onRefresh: controller.fetchProfile,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: controller.isLoadingProfile && profile == null
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                DriverProfileAvatar(
                                  imageUrl: profile?.imageUrl,
                                  radius: 42,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  profile?.fullName.isNotEmpty == true
                                      ? profile!.fullName
                                      : 'Driver',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _ProfileLine(
                                  icon: Icons.badge_outlined,
                                  value: profile?.userName ?? '—',
                                ),
                                const SizedBox(height: 12),
                                _ProfileLine(
                                  icon: Icons.phone_outlined,
                                  value: profile?.phoneNumber ?? '—',
                                ),
                                const SizedBox(height: 12),
                                _ProfileLine(
                                  icon: Icons.local_shipping_outlined,
                                  value: 'Driver',
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onEditProfile,
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit Profile'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.navy,
                                      side: const BorderSide(
                                        color: AppColors.navy,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (controller.profileError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        controller.profileError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        onTap: _isLoggingOut ? null : _logout,
                        leading: _isLoggingOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.logout,
                                color: Color(0xFFF3A523),
                              ),
                        title: const Text('Logout'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const DriverProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final validUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: validUrl
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(Icons.person, size: radius, color: AppColors.navy),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ProfileLine({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF3A523), size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
