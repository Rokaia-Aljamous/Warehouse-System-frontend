// lib/views/screens/common/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/providers/auth_provider.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';
import '../../../utils/constants.dart';
import '../warehouse/warehouse_home.dart';
// 🌟 كلاس السائق في المشروع الثاني اسمه MyTasksScreen (موجود في driver/driver_home_screen.dart)
import '../driver/driver_home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    // درجة الذهب المطلوبة للأيقونات
    const iconGoldColor = Color(0xFFF3A523);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // 🌟 استدعاء الهيدر المشترك
          AuthTopHeader(height: h * 0.32),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Login', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- User Name ----
                  Text('USER NAME', style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: 'name',
                      prefixIcon: Icon(
                        Icons
                            .person_outline_rounded, // 🌟 تم التعديل هنا لأيقونة البروفايل
                        color: iconGoldColor,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ---- Password ----
                  Text('PASSWORD', style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: iconGoldColor,
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: theme.colorScheme.outline,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ---- زر Login ----
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ---- Forgot Password ----
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.error,
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

  // =========================================================================
  // 🌟 منطق تسجيل الدخول — يمر عبر AuthProvider (لا يستدعي AuthService مباشرة)
  // =========================================================================
  Future<void> _handleLogin() async {
    final userName = _emailController.text.trim();
    final password = _passwordController.text;

    if (userName.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your username and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(userName, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // إذا كان يجب تغيير كلمة المرور عند أول دخول → اعرض الـ Bottom Sheet.
      if (authProvider.mustChangePassword) {
        showProtectionBottomSheet(context);
        return;
      }

      // 🌟 التوجيه حسب دور المستخدم (staff → مستودع / driver → سائق)
      final role = authProvider.currentRole;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'driver'
              ? const MyTasksScreen()
              : const WarehouseHome(),
        ),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
    );
  }
}

// =========================================================================
// 🌟 Bottom Sheet الخاص بتغيير كلمة المرور الإلزامي عند أول تسجيل دخول.
//
// تم تحويله من دالة إلى StatefulWidget مستقل حتى نتمكن من:
//   - إدارة الـ controllers بشكل صحيح (dispose).
//   - إدارة حالة التحميل / الأخطاء بشكل مستقل عن الشاشة الأم.
//   - استدعاء AuthProvider.changePassword وربط زر Confirm بالـ API فعلياً.
// =========================================================================
void showProtectionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) => const _ProtectionBottomSheet(),
  );
}

class _ProtectionBottomSheet extends StatefulWidget {
  const _ProtectionBottomSheet();

  @override
  State<_ProtectionBottomSheet> createState() => _ProtectionBottomSheetState();
}

class _ProtectionBottomSheetState extends State<_ProtectionBottomSheet> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---- استدعاء API تغيير كلمة المرور عبر AuthProvider ----
  Future<void> _handleConfirm() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.changePassword(
      password: newPassword,
      passwordConfirmation: confirmPassword,
    );

    if (!mounted) return;

    if (success) {
      // أغلق الـ Bottom Sheet ثم وجّه المستخدم حسب دوره.
      Navigator.pop(context);

      final role = authProvider.currentRole;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              role == 'driver' ? const MyTasksScreen() : const WarehouseHome(),
        ),
        (route) => false,
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage =
          authProvider.errorMessage ?? 'Failed to change password';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'For Protection',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You must set a password to ensure your account is protected.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'NEW PASSWORD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              letterSpacing: 0.5,
            ),
          ),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFFF3A523),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'CONFIRM PASSWORD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              letterSpacing: 0.5,
            ),
          ),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFFF3A523),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),

          // ---- رسالة الخطأ (تظهر فقط إن وُجدت) ----
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleConfirm,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm password'),
            ),
          ),
        ],
      ),
    );
  }
}
