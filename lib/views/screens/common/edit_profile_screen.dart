// lib/views/screens/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/providers/auth_provider.dart';
import '../../../utils/constants.dart';
import '../../widgets/auth_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback onBack;

  const EditProfileScreen({super.key, required this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthdayController;

  bool _initialized = false;
  bool _isEditing = false;
  File? _pickedImage; // صورة جديدة مختارة محلياً (قبل الرفع)

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _birthdayController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
    });
  }

  void _prefillFromProvider(AuthProvider auth) {
    if (_initialized && _isEditing) return;
    _nameController.text = auth.profileFullName ?? '';
    _phoneController.text = auth.profilePhoneNumber ?? '';
    _birthdayController.text = auth.profileBirthday ?? '';
    _initialized = true;
  }

  Future<void> _pickBirthday() async {
    if (!_isEditing) return;

    final now = DateTime.now();
    final initial = DateTime.tryParse(_birthdayController.text) ??
        DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // ---- اختيار صورة جديدة (بس لما تكوني بوضع التعديل) ----
  Future<void> _pickPhoto() async {
    if (!_isEditing) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _handleSave(AuthProvider auth) async {
    final success = await auth.updateProfile(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text,
      birthday: _birthdayController.text.trim().isEmpty
          ? null
          : _birthdayController.text.trim(),
      profileImage: _pickedImage,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEditing = false;
        _pickedImage = null; // الصورة الجديدة صارت محفوظة بالسيرفر
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Failed to update profile')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _prefillFromProvider(auth);

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          Stack(
            children: [
              ReceivingTopHeader(
                height: MediaQuery.of(context).size.height * 0.22,
                title: 'Edit Profile',
              ),
              // ---- طبقة شفافة فوق سهم الرجوع المدمج، بتوجّه الضغطة
              // لـ widget.onBack بدل Navigator.pop (بدون إضافة سهم ظاهر ثاني) ----
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onBack,
                    ),
                  ),
                ),
              ),
              // ---- أيقونة التعديل بالزاوية العلوية اليمنى ----
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    _isEditing ? Icons.edit : Icons.edit_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                ),
              ),
            ],
          ),

          Expanded(
            child: Transform.translate(
              // رفع كل محتوى الشاشة (الصورة + الحقول) فوق شوي، وكلهم
              // جوا نفس الـ ListView فبيتحركوا مع السكرول كوحدة واحدة.
              offset: const Offset(0, -28),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  // ---- الصورة (قابلة للتعديل بوضع التعديل فقط) ----
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (auth.profileImageUrl != null &&
                                        auth.profileImageUrl!.isNotEmpty)
                                    ? NetworkImage(auth.profileImageUrl!)
                                        as ImageProvider
                                    : null,
                            child: (_pickedImage == null &&
                                    (auth.profileImageUrl == null ||
                                        auth.profileImageUrl!.isEmpty))
                                ? const Icon(Icons.person,
                                    size: 40, color: AppColors.navy)
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.navy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Full Name'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _nameController,
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Username'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller:
                        TextEditingController(text: auth.profileUserName ?? ''),
                    icon: Icons.badge_outlined,
                    enabled: false, // ممنوع من الباك اند (prohibited)
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Phone Number'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Birthday'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickBirthday,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _birthdayController,
                        icon: Icons.cake_outlined,
                        enabled: _isEditing,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isEditing && !auth.isLoading)
                          ? () => _handleSave(auth)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.navy),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.navy,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87));

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        // لون نص المعلومات المدخلة = كحلي (لون التطبيق)، مو رمادي
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}