// lib/views/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/providers/auth_provider.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';
import '../../../utils/constants.dart';
import 'otp_verification_screen.dart';
// الهيدر المشترك النظيف

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    // 🌟 الدرجة الذهبية للأيقونات متل الـ Login تماماً
    const iconGoldColor = Color(0xFFF3A523);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // بيج بالكامل من الثيم
      body: Column(
        children: [
          // ---- الهيدر المشترك المستقر ----
          AuthTopHeader(height: h * 0.32),

          // ============================================================
          // محتوى الفورم
          // ============================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- 🌟 العنوان المصحح (أرفع ومتناسق مع اللوغ إن) ----
                  Text(
                    'Forget Password?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500, // جعل الخط أرفع وأكثر أناقة
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ---- الوصف ----
                  Text(
                    'Please enter your phone number. You will receive a 4-digit verification code via WhatsApp for verification.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ---- تسمية الحقل ----
                  Text('PHONE NUMBER', style: theme.textTheme.bodySmall),

                  const SizedBox(height: AppSpacing.xs),

                  // ---- 🌟 حقل الإدخال (خط سفلي شفاف مطاطي مع الخلفية البيج) ----
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      hintText: '+963 9xx xxx xxx',
                      // 🌟 الأيقونة تم تعديلها لتكون هاتف (Phone) صريح وباللون الذهبي المعتمد
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: iconGoldColor,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ---- زر Send OTP ----
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              // ---- منطق إرسال OTP مأخوذ من المشروع الأول ----
                              final success = await authProvider
                                  .sendForgotPassword(_phoneController.text);

                              if (!mounted) return;

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP sent successfully'),
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OtpVerificationScreen(),
                                  ),
                                );
                              } else if (authProvider.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authProvider.errorMessage!),
                                  ),
                                );
                              }
                            },
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send OTP'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ---- رابط العودة للوغ إن ----
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Back to login',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error, // يقرأ الأحمر من الكونست
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
