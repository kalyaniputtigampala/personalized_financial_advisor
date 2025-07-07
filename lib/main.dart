import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:personalized_financial_advisor/screens/register_screen.dart';
import 'firebase_options.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_page.dart';
import 'screens/EmailVerificationScreen.dart';
import 'screens/forgot_password_screen.dart'; // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Notification Service

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainPage(),
        '/email-verification': (context) => EmailVerificationScreen(
          email: ModalRoute.of(context)?.settings.arguments as String?,
        ),
        '/forgot-password': (context) => const ForgotPasswordScreen(), // Add this route
        // Add other routes like '/home': (context) => HomeScreen(), if needed
      },
      home: FlutterSplashScreen(
        duration: const Duration(milliseconds: 2000),
        nextScreen: const LoginScreen(),
        backgroundColor: Colors.white,
        setStateTimer: Duration(seconds: 6),
        splashScreenBody: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 200,
                child: Image.asset('assets/images/pfa_logo.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}