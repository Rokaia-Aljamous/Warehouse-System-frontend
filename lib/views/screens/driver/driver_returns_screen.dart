import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';
import 'package:stock_app/views/widgets/driver_task_card.dart';

class DriverReturnsScreen extends StatefulWidget {
  final ValueChanged<DriverTask> onOpenTask;

  const DriverReturnsScreen({super.key, required this.onOpenTask});

  @override
  State<DriverReturnsScreen> createState() => _DriverReturnsScreenState();
}

class _DriverReturnsScreenState extends State<DriverReturnsScreen> {
  bool _showPending = true;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverController>();
    final tasks = _showPending
        ? controller.pendingReturnTasks
        : controller.completedReturnTasks;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(
            height: MediaQuery.of(context).size.height * 0.22,
            title: 'Returns',
          ),
          Transform.translate(
            offset: const Offset(0, -50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.navy.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [_tab('Pending', true), _tab('Completed', false)],
                ),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Builder(
                builder: (context) {
                  if (controller.isLoadingTasks && tasks.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.tasksError != null && tasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.tasksError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: controller.fetchTasks,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (tasks.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: controller.fetchTasks,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 150),
                          Center(
                            child: Text(
                              _showPending
                                  ? 'No pending return pickups'
                                  : 'No completed return pickups',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.fetchTasks,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return DriverTaskCard(
                          task: task,
                          onTap: () => widget.onOpenTask(task),
                        );
                      },
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

  Widget _tab(String label, bool pending) {
    final selected = _showPending == pending;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showPending = pending),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF3EDE4) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.navy : Colors.black54,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
