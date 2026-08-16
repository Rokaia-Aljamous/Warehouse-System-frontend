// lib/views/screens/warehouse/my_orders_tab_screen.dart
//
// شاشة "Request List" (تبويبات Archive / Incoming / Request List) —
// مربوطة بالكامل الآن بـ DestructionController:
//   GET  /workers/disposals   -> تبويبَي Archive و Request List
//   POST /workers/disposals   -> فورم "Destruction Request" (Submit Request)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/destruction_controller.dart';
import '../../../controllers/order_controller.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';
import '../../../views/widgets/barcode_scanner_sheet.dart';
import 'archive_screen.dart';
import 'incoming_screen.dart';
import 'disposal_details_screen.dart';

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
      setState(() {}); // لإظهار/إخفاء الـ FAB حسب التبويب الحالي
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DestructionController>().fetchDisposals();
      context.read<OrderController>().fetchDestructionTasks();
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
    return Consumer<DestructionController>(
      builder: (context, controller, _) {
        if (controller.isLoadingList && controller.disposals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.listError != null && controller.disposals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 36),
                  const SizedBox(height: 12),
                  Text(controller.listError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => controller.fetchDisposals(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // بتاب "قائمة طلباتي" منعرض بس الطلبات يلي لسا Pending (ما توافق
        // عليها الأدمن بعد). أول ما تصير approved، بتختفي من هون تلقائياً
        // وبتظهر بتاب Archive بس (شوفي ArchiveTabContent).
        final items = controller.disposals
            .where((d) => d.status != 'approved')
            .toList();

        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'No requests yet — tap + to create a destruction request',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchDisposals(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final d = items[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DisposalDetailsScreen(disposalId: d.id),
                    ),
                  );
                },
                child: Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    Text(
                      // raw status متل ما إجا من الباك بالضبط، بس بلون
                      // حسب القيمة: approved أخضر / pending أحمر
                      d.status ?? '-',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(d.status),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.inventory_2_outlined, d.displayTitle),
                    _buildInfoRow(Icons.shopping_cart_outlined,
                        'Qty: ${d.quantity} Units'),
                    if (d.damageReason != null)
                      _buildInfoRow(
                          Icons.warning_amber_rounded, d.damageReason!),
                  ],
                ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // أخضر لـ approved، أحمر لـ pending، رمادي لأي قيمة تانية (raw من الباك)
  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFD32F2F);
      default:
        return AppColors.navy;
    }
  }

  void _showCreateRequestBottomSheet(BuildContext context) {
    final productController = TextEditingController();
    final causeController = TextEditingController();
    int quantity = 1;
    bool isFormFilled = false;

    final destructionController = context.read<DestructionController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            void checkForm() {
              setModalState(() {
                isFormFilled =
                    productController.text.isNotEmpty &&
                    causeController.text.isNotEmpty;
              });
            }

            productController.addListener(checkForm);
            causeController.addListener(checkForm);

            Future<void> handleSubmit() async {
              setModalState(() {}); // يعكس isSubmitting فور الضغط

              final success = await destructionController.createDisposal(
                barcode: productController.text.trim(),
                quantity: quantity,
                damageReason: causeController.text.trim(),
              );

              if (!sheetContext.mounted) return;

              if (success) {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      destructionController.submitSuccessMessage ??
                          'Destruction request submitted',
                    ),
                    backgroundColor: AppColors.navy,
                  ),
                );
                _tabController.animateTo(2); // اعرضلها فوراً بتبويب Request List (طلباتي)
              } else {
                setModalState(() {});
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      destructionController.submitError ??
                          'Failed to submit request',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                          readOnly: true,
                          onTap: () async {
                            final scanned = await Navigator.push<String>(
                              sheetContext,
                              MaterialPageRoute(
                                builder: (_) => const BarcodeScannerScreen(),
                              ),
                            );
                            if (scanned != null && scanned.isNotEmpty) {
                              productController.text = scanned;
                              checkForm();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Tap to scan product barcode',
                            hintStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.black38,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.black54,
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
                          onPressed: (isFormFilled &&
                                  !destructionController.isSubmitting)
                              ? handleSubmit
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
                          child: destructionController.isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
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
}