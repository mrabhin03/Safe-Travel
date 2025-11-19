import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'travel_page.dart';
import 'db_helper.dart';
import 'function.dart';
import 'SmallFunctions/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔥 Background message received: ${message.notification?.title}");
}

void main() async {
  await Special.initSystem();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await DBHelper.initDB();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {'/travel': (_) => const TravelPage()},
      title: 'Vehicle Travel',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.data == null) {
          return const LoginPage();
        }
        _initializeAfterLaunch();
        FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;
        fiam.triggerEvent("app_open");
        return const TravelPage();
      },
    );
  }
}

Future<void> _initializeAfterLaunch() async {
  try {
    await Special.initSystem();
  } catch (e, st) {
    print('Error in Special.initSystem: $e\n$st');
  }

  try {
    // Initialize local notifications first so the plugin has a valid
    // small icon resource available before any .show() calls.
    await LocalNotificationService.initialize();

    await FCMService.requestPermissionOnce();
    FCMService.initFCM();
    await FCMService.printToken();
  } catch (e, st) {
    print('FCM initialization failed: $e\n$st');
  }
}
