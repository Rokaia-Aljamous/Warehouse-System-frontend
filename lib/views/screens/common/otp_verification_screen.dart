import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/providers/auth_provider.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  String? _errorText;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  // ---- التحقق الحقيقي من السيرفر قبل الانتقال ----
  Future<void> _handleContinue() async {
    final otp = _otpValue;

    if (otp.length != 6) {
      setState(() => _errorText = 'Please enter the full 6-digit code');
      return;
    }

    setState(() => _errorText = null);

    final authProvider = context.read<AuthProvider>();
    final isValid = await authProvider.verifyOtp(otp);

    if (!mounted) return;

    if (isValid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(initialOtp: otp)),
      );
    } else {
      setState(() {
        _errorText = authProvider.errorMessage ?? 'Invalid OTP code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AuthTopHeader(height: h * 0.25),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Verification',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We sent a code to your whatsapp. Check and',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please Enter your 6-digit code.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 120),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return _OtpBox(
                        controller: _controllers[index],
                        first: index == 0,
                        last: index == 5,
                      );
                    }),
                  ),

                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],

                  const SizedBox(height: 60),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F3151),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleContinue,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't receive the code? ",
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Send Again',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text(
                        'Back to login',
                        style: TextStyle(
                          color: Color(0xFF1F3151),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final bool first;
  final bool last;

  const _OtpBox({
    required this.controller,
    required this.first,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFDED6CF), width: 1.5),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          autofocus: first,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          showCursor: false,
          enableInteractiveSelection: false,
          contextMenuBuilder: (context, editableTextState) =>
              const SizedBox.shrink(),
          enableSuggestions: false,
          autocorrect: false,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F3151),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            if (value.length == 1 && !last) FocusScope.of(context).nextFocus();
            if (value.isEmpty && !first) FocusScope.of(context).previousFocus();
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );
  }
}
