
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Stream يبث true (متصل) / false (غير متصل) عند كل تغيير بحالة الاتصال.
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> _init() async {
    final initial = await _connectivity.checkConnectivity();
    _isOnline = _resultIndicatesOnline(initial);

    _connectivity.onConnectivityChanged.listen((result) {
      final online = _resultIndicatesOnline(result);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  bool _resultIndicatesOnline(List<ConnectivityResult> results) {
    // connectivity_plus بيرجع نوع الاتصال (wifi/mobile/none...) مش
    // ضمان فعلي إنه في نت شغال، بس كافي كبداية لتحديد "أونلاين محتمل"
    // مقابل "مقطوع أكيد" (none).
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _resultIndicatesOnline(result);
    return _isOnline;
  }

  void dispose() {
    _controller.close();
  }
}