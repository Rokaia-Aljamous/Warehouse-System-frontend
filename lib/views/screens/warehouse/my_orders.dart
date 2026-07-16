// lib/views/screens/warehouse/my_orders_tab_screen.dart

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';
import 'archive_screen.dart';
import 'incoming_screen.dart';

class MyOrdersTabScreen extends StatefulWidget {
  final int initialIndex;
  const MyOrdersTabScreen({super.key, this.initialIndex = 2});

  @override
  State<MyOrdersTabScreen> createState() => _MyOrdersTabScreenState();
}

class _MyOrdersTabScreenState extends State<MyOrdersTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentTitle = 'My Order';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _setPageTitle(widget.initialIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _setPageTitle(_tabController.index);
      }
    });
  }

  void _setPageTitle(int index) {
    setState(() {
      switch (index) {
        case 0:
          _currentTitle = 'Archive';
          break;
        case 1:
          _currentTitle = 'Incoming';
          break;
        case 2:
          _currentTitle = 'Request List';
          break;
        default:
          _currentTitle = 'Request List';
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ReceivingTopHeader(
              height: screenHeight * 0.22,
              title: _currentTitle,
            ),
          ),
          Positioned(
            top: (screenHeight * 0.22) - 25,
            left: 24,
            right: 24,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: const Color(0xFFCBCBD9),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: AppColors.navy,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Archive'),
                  Tab(text: 'Incoming'),
                  Tab(text: 'Request List'),
                ],
              ),
            ),
          ),
          Positioned.fill(
            top: (screenHeight * 0.22) + 40,
            child: TabBarView(
              controller: _tabController,
              children: [
                const ArchiveTabContent(),
                const IncomingTabContent(),
                _buildMyOrderContent(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (_tabController.index == 2)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
              child: FloatingActionButton(
                onPressed: () => _showCreateRequestBottomSheet(context),
                backgroundColor: const Color(0xFFF3F3FA),
                elevation: 3,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: AppColors.navy, size: 26),
              ),
            )
          : null,
    );
  }

  Widget _buildMyOrderContent() {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          SizedBox(height: 40),
          Opacity(
            opacity: 0.4,
            child: Text(
              'No current requests',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: AppColors.navy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRequestBottomSheet(BuildContext context) {
    final productController = TextEditingController();
    final causeController = TextEditingController();
    int quantity = 1;
    bool isFormFilled = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void checkForm() {
              setModalState(() {
                isFormFilled =
                    productController.text.isNotEmpty &&
                    causeController.text.isNotEmpty;
              });
            }

            productController.addListener(checkForm);
            causeController.addListener(checkForm);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Destruction Request',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Product',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: productController,
                          decoration: const InputDecoration(
                            hintText: 'Enter product name or scan',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.black38,
                            ),
                            prefixIcon: Icon(
                              Icons.qr_code_scanner,
                              color: Colors.black54,
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.numbers,
                              color: Colors.black54,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                if (quantity > 1) {
                                  setModalState(() => quantity--);
                                }
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(Icons.remove, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setModalState(() => quantity++);
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(Icons.add, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Reason for Destruction',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: causeController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Describe the reason for destruction...',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.black38,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.black54,
                                size: 22,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isFormFilled
                              ? () {
                                  Navigator.pop(context);
                                  _showDocumentationSheet(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormFilled
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFE0E0E0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isFormFilled
                                    ? const Color(0xFF90EE90)
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Submit Request',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isFormFilled
                                  ? AppColors.navy
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDocumentationSheet(BuildContext context) {
    bool isFilled = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // مقبض السحب
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // العنوان
                  const Text(
                    'Documentation',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scanner label
                  Row(
                    children: const [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.black54,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Scanner',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // أيقونة الماسح
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setModalState(() => isFilled = true);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          size: 50,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // أزرار cancel و done
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'cancel',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isFilled
                              ? () => Navigator.pop(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFilled
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFE0E0E0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isFilled
                                    ? const Color(0xFF90EE90)
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'done',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isFilled ? AppColors.navy : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderResultScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.beige,
          body: Builder(
            builder: (context) {
              final screenHeight = MediaQuery.of(context).size.height;
              return Column(
                children: [
                  ReceivingTopHeader(
                    height: screenHeight * 0.22,
                    title: 'Request List',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.navy.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rejected',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildOrderDetailRow(
                                Icons.inventory_2_outlined,
                                'Shipment Name',
                              ),
                              _buildOrderDetailRow(
                                Icons.shopping_cart_outlined,
                                'Qty: 1 Units',
                              ),
                              _buildOrderDetailRow(
                                Icons.warning_amber_rounded,
                                'Cause of damage',
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showCreateRequestBottomSheet(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.beige,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.navy.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.navy,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.navy.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Awaiting Approval',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildOrderDetailRow(
                                Icons.inventory_2_outlined,
                                'Shipment Name',
                              ),
                              _buildOrderDetailRow(
                                Icons.shopping_cart_outlined,
                                'Qty: 1 Units',
                              ),
                              _buildOrderDetailRow(
                                Icons.warning_amber_rounded,
                                'Cause of damage',
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showCreateRequestBottomSheet(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.beige,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.navy.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.navy,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
        ],
      ),
    );
  }
}
