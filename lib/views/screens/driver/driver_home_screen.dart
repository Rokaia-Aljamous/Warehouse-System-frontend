import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/screens/driver/driver_task_details_screen.dart';
import 'package:stock_app/views/widgets/delivery_bottom_nav.dart';
import 'package:stock_app/views/widgets/driver_task_card.dart';

class MyTasksScreen extends StatelessWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverController()..initialize(),
      child: const _DriverShell(),
    );
  }
}

class _DriverShell extends StatefulWidget {
  const _DriverShell();

  @override
  State<_DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<_DriverShell> {
  Future<void> _openTask(DriverTask task) async {
    final controller = context.read<DriverController>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: DriverTaskDetailsScreen(task: task),
        ),
      ),
    );
    if (mounted) await controller.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: _DriverHomePage(onOpenTask: _openTask),
      bottomNavigationBar: DeliveryBottomNav(currentIndex: 0, onTap: (_) {}),
    );
  }
}

class _DriverHomePage extends StatelessWidget {
  final ValueChanged<DriverTask> onOpenTask;

  const _DriverHomePage({required this.onOpenTask});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverController>();
    final summary = controller.summary;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _DriverHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
              sliver: SliverToBoxAdapter(
                child: _SummaryCard(
                  total: summary.total,
                  completed: summary.completed,
                  percentage: summary.completionPercentage,
                  isLoading: controller.isLoadingSummary,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Main Driver Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    Text(
                      '${controller.pendingTasks.length} pending',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isLoadingTasks && controller.pendingTasks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.tasksError != null &&
                controller.pendingTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _DriverError(
                  message: controller.tasksError!,
                  onRetry: controller.fetchTasks,
                ),
              )
            else if (controller.pendingTasks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No pending driver tasks')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList.separated(
                  itemCount: controller.pendingTasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = controller.pendingTasks[index];
                    return DriverTaskCard(
                      task: task,
                      onTap: () => onOpenTask(task),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int completed;
  final double percentage;
  final bool isLoading;

  const _SummaryCard({
    required this.total,
    required this.completed,
    required this.percentage,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0
        ? 0.0
        : (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isLoading && total == 0
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Tasks",
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 46,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completed completed today',
                        style: const TextStyle(
                          color: Color(0xFFF3A523),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 108,
                        height: 108,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 13,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.navy,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$completed/$total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DriverController>().profile;
    return Container(
      height: 160,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 18,
        24,
        22,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Today's Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile?.fullName.isNotEmpty == true
                      ? 'Welcome, ${profile!.fullName}'
                      : 'Your assigned delivery tasks',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_shipping_outlined,
            color: Color(0xFFF3A523),
            size: 42,
          ),
        ],
      ),
    );
  }
}

class _DriverError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DriverError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
