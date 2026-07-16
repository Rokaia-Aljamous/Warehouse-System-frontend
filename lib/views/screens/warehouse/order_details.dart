// lib/views/screens/warehouse/order_details.dart

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  // مصفوفة تفاعلية لإدارة حالة فحص المنتجات الثلاثة داخل الواجهة
  final List<bool> _scannedProducts = [false, false, false];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // التحقق مما إذا تم مسح جميع المنتجات لتفعيل حالة زر Confirm واختفاء كرت التفاصيل
    bool allScanned = _scannedProducts.every((scanned) => scanned == true);

    return Scaffold(
      backgroundColor: AppColors.beige, // اللون البيج الافتراضي للواجهة الخلفية
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. الهيدر المشترك - عاد للشكل النظيف والأصلي ويعمل مباشرة الآن
          ReceivingTopHeader(
            height: screenHeight * 0.22,
            title: 'Order Details',
          ),

          // محتوى الصفحة المرتفع للأعلى قليلاً ليناسب انحناء الهيدر
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  // الجزء القابل للتمرير (يحتوي على الكرت وقائمة المنتجات)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. كرت معلومات العميل والطلب الأساسية (يختفي فور اكتمال المسح)
                          if (!allScanned) ...[
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.navy.withOpacity(0.6),
                                  width: 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        color: AppColors.navy.withOpacity(0.7),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'name custumer',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text(
                                        '#88',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: AppColors.navy.withOpacity(0.7),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Due : 2 hours',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppColors.navy.withOpacity(0.7),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'number of product',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // عنوان قائمة العناصر المتواجدة في الطلب
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              'ITEMS IN ORDER',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3. قائمة كروت المنتجات التفاعلية
                          _buildInteractiveProductCard(
                            index: 0,
                            productName: 'Product Name',
                            qty: 5,
                            location: 'Aisle 4, Shelf B2',
                            iconBgColor: const Color(0xFFFFB3B3),
                          ),
                          _buildInteractiveProductCard(
                            index: 1,
                            productName: 'Product Name',
                            qty: 5,
                            location: 'Aisle 4, Shelf B2',
                            iconBgColor: const Color(0xFFFFD984),
                          ),
                          _buildInteractiveProductCard(
                            index: 2,
                            productName: 'Product Name',
                            qty: 5,
                            location: 'Aisle 4, Shelf B2',
                            iconBgColor: const Color(0xFFCCE6CD),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // 4. زر الـ Confirm السفلي الذكي الملون بالأخضر المطلوب BBF7D0 عند اكتمال المسح
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: allScanned ? 180 : 160,
                        height: 50,
                        decoration: BoxDecoration(
                          color: allScanned
                              ? const Color(0xFFBBF7D0)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.navy.withOpacity(0.6),
                            width: 1.0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (allScanned) {
                              // استدعاء نافذة التصميم الأصلي المحدثة بالتدرج الدائري من المنتصف
                              _showCustomFigmaBottomSheet(
                                context,
                                screenHeight,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Confirm',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                allScanned
                                    ? Icons.check_circle_rounded
                                    : Icons.verified_outlined,
                                color: AppColors.navy,
                                size: 22,
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
        ],
      ),
    );
  }

  // 5. دالة إظهار النافذة السفلية المخصصة بالتصميم المتدرج الدائري
  void _showCustomFigmaBottomSheet(BuildContext context, double screenHeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return Container(
          width: double.infinity,
          height: screenHeight * 0.38,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [Colors.white, Color(0xFFE3E4E8), Color(0xFF8E94A0)],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(55),
              topRight: Radius.circular(55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.pop(context); // إغلاق النافذة السفلية
              Navigator.pop(context); // العودة لشاشة قائمة الطلبات الرئيسية
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Confirm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 58,
                      color: AppColors.navy.withOpacity(0.9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ويدجت مخصصة لبناء كروت المنتجات بشكل تفاعلي يدعم التغيير والـ Scan الفوري المحدث باللون الجديد BBF7D0
  Widget _buildInteractiveProductCard({
    required int index,
    required String productName,
    required int qty,
    required String location,
    required Color iconBgColor,
  }) {
    bool isScanned = _scannedProducts[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.layers_outlined,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Qty: $qty Units',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      location,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _scannedProducts[index] = !_scannedProducts[index];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isScanned ? const Color(0xFFBBF7D0) : iconBgColor,
                borderRadius: BorderRadius.circular(12),
                border: isScanned
                    ? Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Icon(
                isScanned
                    ? Icons.check_circle_outline_rounded
                    : Icons.qr_code_scanner_rounded,
                color: isScanned ? AppColors.navy : Colors.black87,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
