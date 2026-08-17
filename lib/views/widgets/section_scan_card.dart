// lib/views/widgets/section_scan_card.dart
//
// كرت مسح القسم (Section) — "مكان المنتج" الفعلي بالمستودع. يظهر بأعلى
// شاشات تفاصيل المهام الأربعة (تحضير/استلام/مرتجعات/إتلاف)، فوق قائمة
// المنتجات مباشرة.
//
// نفس تصميم كرت المنتج (_ProductScanCard) بكل الشاشات الأربعة، بس:
//   - بدون حواف (لا Border) — بعكس كرت المنتج يلي إله حافة رمادية خفيفة
//   - بخلفية حمراء فاتحة (بدل الأبيض) — نفس AppColors.red المستخدم
//     أصلاً لحالة "لسا ما انمسح شي" بكرت المنتج
//   - نفس زر/أيقونة الكاميرا (qr_code_scanner_rounded) تمامًا
//
// السلوك: أول مسح لباركود قسم بيفعّل منتجاته (تصير قابلة للمسح بكروتها
// تحت). العامل يقدر يمسح أكتر من قسم بالتتابع — كل قسم جديد بيضيف
// منتجاته لقائمة المنتجات المفعّلة (تراكمي، مش استبدال).

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SectionScanCard extends StatelessWidget {
  final String? activeSectionName;
  final VoidCallback onScan;
  // لما تكون المهمة completed، الكرت لازم يظهر دايمًا أخضر (تم مسحه)
  // وممنوع تعديله — عرض فقط. مستقل عن activeSectionName لأنه endpoint
  // تفاصيل المهمة ما بيرجّع اسم القسم أصلاً (بيرجعه بس رد /scan وقت
  // المسح الحقيقي بنفس الجلسة)، فما منقدر نعتمد عليه لتحديد الحالة.
  final bool isReadOnly;

  const SectionScanCard({
    super.key,
    required this.activeSectionName,
    required this.onScan,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveSection =
        activeSectionName != null && activeSectionName!.trim().isNotEmpty;

    // لما ينمسح القسم بنجاح (أو المهمة completed بالأصل)، الكرت بيتحول من
    // أحمر لأخضر (نفس لون حالة "done" بكرت المنتج AppColors مثل
    // 0xFFBBF7D0) بدل ما يضل أحمر دايمًا.
    final isDone = isReadOnly || hasActiveSection;

    final accentColor = isDone ? const Color(0xFF2E7D32) : AppColors.red;
    final bgColor = isDone
        ? const Color(0xFFBBF7D0)
        : AppColors.red.withOpacity(0.12);
    final iconBgColor = isDone
        ? const Color(0xFF2E7D32).withOpacity(0.18)
        : AppColors.red.withOpacity(0.22);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        // بلا Border بقصد — بعكس كرت المنتج
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActiveSection
                      ? activeSectionName!.trim()
                      : (isReadOnly ? 'Section scanned' : 'Scan a section to begin'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_outline_rounded
                          : Icons.location_on_outlined,
                      size: 18,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isReadOnly
                            ? 'Task completed — view only'
                            : (hasActiveSection
                                ? 'Active section — its products are unlocked below'
                                : 'Scan its barcode to unlock its products'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isReadOnly ? null : onScan,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDone
                    ? Icons.check_circle_outline_rounded
                    : Icons.qr_code_scanner_rounded,
                color: accentColor,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
