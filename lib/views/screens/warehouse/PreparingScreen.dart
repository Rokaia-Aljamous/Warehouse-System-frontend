// lib/views/screens/warehouse/preparing_screen.dart

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';
import 'order_details.dart'; // سيوجهكِ لصفحة تفاصيل التجهيز عند النقر

class PreparingScreen extends StatefulWidget {
  const PreparingScreen({super.key});

  @override
  State<PreparingScreen> createState() => _PreparingScreenState();
}

class _PreparingScreenState extends State<PreparingScreen> {
  // متغير لإدارة التبويب الحالي (Pending أو Completed)
  bool isPendingSelected = true;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          // ============================================================
          // 1. الهيدر - استدعاء الميلان المشترك مع عنوان التجهيز
          // ============================================================
          ReceivingTopHeader(height: screenHeight * 0.22, title: 'Preparation'),

          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                // التبويب المخصص (Tabs) بنفس أسلوبكِ الأنيق
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.greyLine.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // تبويب Pending (الطلبات المنتظرة للتجهيز)
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => isPendingSelected = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPendingSelected
                                    ? const Color(0xFFF3EDE4)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Pending',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                  decoration: isPendingSelected
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  decorationColor: AppColors.navy,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // تبويب Completed (الطلبات المجهزة / المكتملة)
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => isPendingSelected = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isPendingSelected
                                    ? const Color(0xFFF3EDE4)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Completed',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                  decoration: !isPendingSelected
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  decorationColor: AppColors.navy,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // الخط الفاصل المشابه لواجهة الاستلام
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(color: Colors.black12, thickness: 1),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // قائمة الكروت التفاعلية للطلبات (Cards List)
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 0,
                ),
                itemCount: 2, // عدد تجريبي للطلبات
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // ينتقل لصفحة تفاصيل التجهيز عند الضغط في كلا التبويبين (Pending أو Completed)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderDetailsScreen(),
                        ),
                      );
                    },
                    child: _OrderCard(
                      showDueTime: isPendingSelected,
                      dateText:
                          '13/2/2026', // تاريخ التجهيز والأرشفة بتبويب Completed
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// الكرت الموحد والمطابق لـ _OrderCard الخاص بكِ مع تعديل النصوص لتناسب التجهيز
// ============================================================
class _OrderCard extends StatelessWidget {
  final bool showDueTime;
  final String dateText;

  const _OrderCard({required this.showDueTime, required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withOpacity(0.6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order # 92', // رقم تجريبي لطلب تجهيز
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'customer name',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Items to collect: 6', // توضيح عدد المواد المراد جمعها وتجهيزها
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
              // التبديل الذكي: إذا كان معلق يعرض الوقت المتبقي، وإذا اكتمل التجهيز يعرض تاريخ الإنجاز الأخضر
              showDueTime
                  ? Text(
                      'Due: 2 hours',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greenLight,
                      ),
                    )
                  : Text(
                      dateText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greenLight,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
