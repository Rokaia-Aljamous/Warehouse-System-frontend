import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';

class DriverEditProfileScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DriverEditProfileScreen({super.key, required this.onBack});

  @override
  State<DriverEditProfileScreen> createState() =>
      _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState extends State<DriverEditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  bool _initialized = false;
  bool _isEditing = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverController>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _prefill(DriverController controller) {
    if ((_initialized && _isEditing) || controller.profile == null) return;
    final profile = controller.profile!;
    _nameController.text = profile.fullName;
    _usernameController.text = profile.userName;
    _phoneController.text = profile.phoneNumber;
    _birthdayController.text = profile.birthday ?? '';
    _initialized = true;
  }

  Future<void> _pickBirthday() async {
    if (!_isEditing) return;

    final now = DateTime.now();
    final initial =
        DateTime.tryParse(_birthdayController.text) ??
        DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() {
        _birthdayController.text =
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickPhoto() async {
    if (!_isEditing) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone number are required')),
      );
      return;
    }

    final controller = context.read<DriverController>();
    final success = await controller.updateProfile(
      fullName: name,
      phoneNumber: phone,
      birthday: _birthdayController.text.trim().isEmpty
          ? null
          : _birthdayController.text.trim(),
      profileImage: _pickedImage,
    );

    if (!mounted) return;
    if (success) {
      setState(() {
        _isEditing = false;
        _pickedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.profileError ?? 'Failed to update profile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverController>();
    _prefill(controller);

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
              offset: const Offset(0, -28),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                children: [
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
                                : (controller.profile?.imageUrl != null &&
                                      controller.profile!.imageUrl!.isNotEmpty)
                                ? NetworkImage(controller.profile!.imageUrl!)
                                      as ImageProvider
                                : null,
                            child:
                                (_pickedImage == null &&
                                    (controller.profile?.imageUrl == null ||
                                        controller.profile!.imageUrl!.isEmpty))
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.navy,
                                  )
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
                  const _DriverFieldLabel('Full Name'),
                  const SizedBox(height: 6),
                  _DriverField(
                    controller: _nameController,
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  const _DriverFieldLabel('Username'),
                  const SizedBox(height: 6),
                  _DriverField(
                    controller: _usernameController,
                    icon: Icons.badge_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 14),
                  const _DriverFieldLabel('Phone Number'),
                  const SizedBox(height: 6),
                  _DriverField(
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  const _DriverFieldLabel('Birthday'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickBirthday,
                    child: AbsorbPointer(
                      child: _DriverField(
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
                      onPressed: _isEditing && !controller.isSavingProfile
                          ? _save
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.navy),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isSavingProfile
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
}

class _DriverFieldLabel extends StatelessWidget {
  final String text;

  const _DriverFieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
    );
  }
}

class _DriverField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final bool enabled;

  const _DriverField({
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
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
