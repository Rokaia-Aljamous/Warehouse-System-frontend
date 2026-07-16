// lib/views/widgets/auth_header_widgets.dart

import 'package:flutter/material.dart';
import 'package:stock_app/utils/constants.dart';

// ============================================================
// هيدر صفحات الـ Auth (تسجيل الدخول، OTP، إلخ)
// ============================================================
class AuthTopHeader extends StatelessWidget {
  final double height;
  const AuthTopHeader({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: height,
            color: theme.colorScheme.primaryContainer,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(double.infinity, height * 0.30),
              painter: _AuthWavePainter(
                waveColor: theme.scaffoldBackgroundColor,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface,
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 36,
                    color: theme.colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Stock Tereaq',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.surface,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.surface,
                size: 26,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// هيدر شاشات المستودع الداخلية (مع موجة وعنوان)
// ============================================================
class ReceivingTopHeader extends StatelessWidget {
  final double height;
  final String title;
  const ReceivingTopHeader({
    super.key,
    required this.height,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: height,
            color: theme.colorScheme.primaryContainer,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(double.infinity, height * 0.45),
              painter: _ReceivingWavePainter(
                waveColor: theme.scaffoldBackgroundColor,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: screenHeight * 0.035,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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

// ============================================================
// Painters الخاصة بالموجات
// ============================================================
class _ReceivingWavePainter extends CustomPainter {
  final Color waveColor;
  _ReceivingWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = waveColor;
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(0, 0, size.width * 0.20, 0);
    path.lineTo(size.width * 0.85, 0);
    path.quadraticBezierTo(size.width, 0, size.width, -size.height * 0.85);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReceivingWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}

class _AuthWavePainter extends CustomPainter {
  final Color waveColor;
  _AuthWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = waveColor;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height * 0.35,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AuthWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}
