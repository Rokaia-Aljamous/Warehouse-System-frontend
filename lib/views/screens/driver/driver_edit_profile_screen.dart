import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/screens/driver/driver_profile_screen.dart';
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
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  bool _didPrefill = false;
  File? _pickedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _prefill(DriverController controller) {
    if (_didPrefill || controller.profile == null) return;
    final profile = controller.profile!;
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber;
    _birthdayController.text = profile.birthday ?? '';
    _didPrefill = true;
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver profile updated successfully')),
      );
      widget.onBack();
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
                title: 'Edit Driver Profile',
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 6,
                left: 8,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -34),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          if (_pickedImage != null)
                            ClipOval(
                              child: Image.file(
                                _pickedImage!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            DriverProfileAvatar(
                              imageUrl: controller.profile?.imageUrl,
                              radius: 44,
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3A523),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DriverField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _DriverField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _DriverField(
                    controller: _birthdayController,
                    label: 'Birthday (YYYY-MM-DD)',
                    icon: Icons.cake_outlined,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: controller.isSavingProfile ? null : _save,
                      icon: controller.isSavingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _DriverField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFF3A523)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
