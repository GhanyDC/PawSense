import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pawsense/pages/mobile/auth/sign_up_page.dart';
import 'package:pawsense/pages/mobile/home_page.dart';
import 'package:pawsense/pages/mobile/auth/sign_in_page.dart';
import 'package:pawsense/pages/mobile/signup.dart';
import 'package:pawsense/pages/web/admin_main.dart';
import 'core/utils/constants.dart';
import 'core/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
  /// Entry point for the PawSense app.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect if running on web
    final bool isWeb = kIsWeb;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawSense',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      // Initial route based on platform
      initialRoute: isWeb ? '/admin_main' : '/signin',

      routes: {
        // Web routes
        '/admin_main': (context) => AdminMain(),

        // Mobile routes
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/uisignup': (context) => const Signup(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
