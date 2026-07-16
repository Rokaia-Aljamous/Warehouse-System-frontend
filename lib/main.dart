import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/providers/auth_provider.dart';
import 'package:stock_app/views/screens/common/login_screen.dart';
// تأكدي أن المسارات أدناه تطابق مجلدات مشروعكِ الحالية
import 'utils/constants.dart';
import 'views/screens/common/welcome_screen.dart';

void main() {
  // 👈 خطوة أمان أساسية لتهيئة خدمات فلاتر قبل إقلاع التطبيق ومنع أي كراش بالثيم والخطوط
  WidgetsFlutterBinding.ensureInitialized();

  // ---- منطق المصادقة مأخوذ من المشروع الأول ----
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     title: 'Stock Tereaq',
      debugShowCheckedModeBanner: false,

      // ---- تطبيق الثيم الشامل والموحد بدقة الفيغما ----
      theme: AppTheme.lightTheme,

      // ---- الشاشة الأولى للتطبيق ----
      themeMode: ThemeMode
          .light, // إجبار التطبيق على الوضع الفاتح ليتطابق مع ألوان التصميم دائماً
     home: const LoginScreen(role: ''),

      // ---- المسارات (Routes) — جاهزة لتفعيلها بمجرد بناء شاشة تسجيل الدخول ----
      // routes: {
      //   '/login':          (ctx) => const LoginScreen(),
      //   '/home_warehouse': (ctx) => const WarehouseHome(),
      //   '/home_driver':    (ctx) => const DriverHome(),
      // },
    );
  }
}
