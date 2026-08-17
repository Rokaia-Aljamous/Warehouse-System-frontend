import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:stock_app/models/driver_profile_model.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/services/api.dart';
import 'package:stock_app/services/auth_service.dart';
import 'package:stock_app/services/driver_task_service.dart';

class DriverController extends ChangeNotifier {
  final DriverTaskService _taskService;
  final AuthService _authService;

  DriverController({DriverTaskService? taskService, AuthService? authService})
    : _taskService = taskService ?? DriverTaskService(),
      _authService = authService ?? AuthService();

  bool isInitializing = false;
  bool isLoadingTasks = false;
  bool isLoadingSummary = false;
  bool isLoadingProfile = false;
  bool isSavingProfile = false;

  String? tasksError;
  String? summaryError;
  String? profileError;

  List<DriverTask> pendingTasks = const [];
  List<DriverTask> completedTasks = const [];
  DriverDailySummary summary = const DriverDailySummary.empty();
  DriverProfile? profile;

  List<DriverTask> get allTasks => [...pendingTasks, ...completedTasks];

  Future<void> initialize() async {
    isInitializing = true;
    notifyListeners();

    await Future.wait([fetchTasks(), fetchDailySummary(), fetchProfile()]);

    isInitializing = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchTasks(), fetchDailySummary(), fetchProfile()]);
  }

  Future<void> fetchTasks() async {
    isLoadingTasks = true;
    tasksError = null;
    notifyListeners();

    final result = await _taskService.getTasks();
    isLoadingTasks = false;

    if (result['success'] == true) {
      final parsed = DriverTasksResponse.fromJson(
        Map<String, dynamic>.from(result['data'] as Map),
      );
      pendingTasks = parsed.pending;
      completedTasks = parsed.completed;
    } else {
      tasksError = result['message']?.toString() ?? 'Failed to load tasks';
    }

    notifyListeners();
  }

  Future<void> fetchDailySummary() async {
    isLoadingSummary = true;
    summaryError = null;
    notifyListeners();

    final result = await _taskService.getDailySummary();
    isLoadingSummary = false;

    if (result['success'] == true) {
      summary = DriverDailySummary.fromJson(
        Map<String, dynamic>.from(result['data'] as Map),
      );
    } else {
      summaryError =
          result['message']?.toString() ?? 'Failed to load today summary';
    }

    notifyListeners();
  }

  Future<DriverTask?> fetchTaskDetails(int taskId) async {
    final result = await _taskService.getTaskDetails(taskId);
    if (result['success'] != true) return null;

    final body = Map<String, dynamic>.from(result['data'] as Map);
    final taskJson = body['task'];
    if (taskJson is! Map) return null;
    return DriverTask.fromJson(Map<String, dynamic>.from(taskJson));
  }

  Future<void> fetchProfile() async {
    isLoadingProfile = true;
    profileError = null;
    notifyListeners();

    final result = await _authService.getProfile();
    isLoadingProfile = false;

    if (result['success'] == true) {
      profile = DriverProfile.fromJson(
        Map<String, dynamic>.from(result['data'] as Map),
        apiBaseUrl: Api.baseUrl,
      );
    } else {
      profileError = result['message']?.toString() ?? 'Failed to load profile';
    }

    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? birthday,
    File? profileImage,
  }) async {
    isSavingProfile = true;
    profileError = null;
    notifyListeners();

    final result = await _authService.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      birthday: birthday,
      profileImage: profileImage,
    );

    isSavingProfile = false;

    if (result['success'] == true) {
      final data = result['data'];
      if (data is Map) {
        profile = DriverProfile.fromJson(
          Map<String, dynamic>.from(data),
          apiBaseUrl: Api.baseUrl,
        );
      }
      notifyListeners();
      await fetchProfile();
      return true;
    }

    profileError = result['message']?.toString() ?? 'Failed to update profile';
    notifyListeners();
    return false;
  }

  Future<bool> updateCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _taskService.updateCurrentLocation(
      latitude: latitude,
      longitude: longitude,
    );
    return result['success'] == true;
  }
}
