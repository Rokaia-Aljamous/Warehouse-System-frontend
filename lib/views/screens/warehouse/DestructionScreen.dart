// lib/views/screens/warehouse/DestructionScreen.dart

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import 'my_orders.dart';
import 'archive_screen.dart';

class DestructionScreen extends StatelessWidget {
  const DestructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.welcomeGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.navy,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const Positioned(
                top: 65,
                left: 24,
                child: Text(
                  'Destruction',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 170),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: screenWidth * 0.88,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ============================================================
                              // صندوق incoming - يروح على تبويب Incoming (index 1)
                              // ============================================================
                              Expanded(
                                child: _buildFigmaBox(
                                  title: 'incoming',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MyOrdersTabScreen(
                                              initialIndex: 1,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              // ============================================================
                              // صندوق my orders - يروح على تبويب My Order (index 2)
                              // ============================================================
                              Expanded(
                                child: _buildFigmaBox(
                                  title: 'my orders',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MyOrdersTabScreen(
                                              initialIndex: 2,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // ============================================================
                          // صندوق archive - يروح على تبويب Archive (index 0)
                          // ============================================================
                          SizedBox(
                            width: (screenWidth * 0.88 - 20) / 2,
                            child: _buildFigmaBox(
                              title: 'archive',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyOrdersTabScreen(
                                          initialIndex: 0,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFigmaBox({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _FigmaStrictBoxPainter(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 55,
                child: CustomPaint(
                  size: const Size(42, 14),
                  painter: _BoxHandlePainter(),
                ),
              ),
              Positioned(
                bottom: 16,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 8,
              right: 8,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Archived',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: ArchiveTabContent()),
        ],
      ),
    );
  }
}

class _FigmaStrictBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    const double lidTopY = 0;
    const double lidBottomY = 25;
    const double slantOffset = 22;

    final fillPaint = Paint()
      ..color = const Color(0xFFEFE8D3)
      ..style = PaintingStyle.fill;

    final fullPath = Path()
      ..moveTo(slantOffset, lidTopY)
      ..lineTo(w - slantOffset, lidTopY)
      ..lineTo(w, lidBottomY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(0, lidBottomY)
      ..close();
    canvas.drawPath(fullPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fullPath, strokePaint);

    final linePath = Path()
      ..moveTo(0, lidBottomY)
      ..lineTo(w, lidBottomY);
    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BoxHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    var path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width / 2, size.height * 1.5, size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
