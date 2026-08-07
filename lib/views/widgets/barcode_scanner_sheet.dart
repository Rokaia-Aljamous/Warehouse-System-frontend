// lib/views/widgets/barcode_scanner_sheet.dart
//
// شاشة مسح باركود فعلية بكاميرا الموبايل (mobile_scanner).
// ⚠️ يتطلب إضافة الحزمة لملف pubspec.yaml:
//     dependencies:
//       mobile_scanner: ^5.2.3
// وصلاحية الكاميرا بـ AndroidManifest.xml / Info.plist (موضّح بالرسالة).
//
// الاستخدام:
//   final barcode = await Navigator.push<String>(
//     context,
//     MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
//   );
//   if (barcode != null) { ... }
//
// تعمل بنمط "مسحة وحدة واحدة": أول باركود يُكتشف، تُغلق الكاميرا فوراً
// وترجع القيمة لصاحب الاستدعاء (نفس منطق "كل مسح = قطعة وحدة").

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/constants.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _handled = true; // منع التقاط أكثر من باركود بنفس اللحظة
    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // إطار توجيه بصري بسيط بمنتصف الشاشة
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greenLight, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point the camera at the barcode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
