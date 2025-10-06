import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home screen after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Motorcycle riding animation
            SizedBox(
              width: isWideScreen ? 400 : 300,
              height: isWideScreen ? 400 : 300,
              child: Lottie.asset(
                'assets/animations/motorcycle_ride.json',
                fit: BoxFit.contain,
                repeat: false,
                animate: true,
              ),
            ),
            const SizedBox(height: 24),
            // Welcome text
            Text(
              'Welcome to MotoDocs AI!',
              style: TextStyle(
                fontSize: isWideScreen ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Starting your engine...',
              style: TextStyle(
                fontSize: isWideScreen ? 18 : 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
