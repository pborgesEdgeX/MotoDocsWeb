import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.getCurrentPlatform(),
  );

  runApp(const MotoDocsApp());
}

class MotoDocsApp extends StatelessWidget {
  const MotoDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'MotoDocs AI',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasTimedOut = false;
  bool _showLoginAnimation = false;
  String? _lastAuthenticatedUserId; // Track user to reset animation on sign out

  @override
  void initState() {
    super.initState();
    // Set a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Provider.of<AuthService>(context, listen: false).authStateChanges,
      builder: (context, snapshot) {
        print('═' * 80);
        print('🔄 AuthWrapper rebuild triggered');
        print('   ConnectionState: ${snapshot.connectionState}');
        print('   hasData: ${snapshot.hasData}');
        print('   hasError: ${snapshot.hasError}');
        print('   data: ${snapshot.data}');
        print('   _showLoginAnimation: $_showLoginAnimation');
        print('   _lastAuthenticatedUserId: $_lastAuthenticatedUserId');
        print('═' * 80);

        // If there's an error, show auth screen immediately
        if (snapshot.hasError) {
          print('❌ Auth error: ${snapshot.error}');
          _showLoginAnimation = false;
          _lastAuthenticatedUserId = null;
          print('➡️  Returning AuthScreen (error)');
          return const AuthScreen();
        }

        // If still waiting for auth state, show splash (but with timeout)
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If we've timed out waiting for auth, force to auth screen
          if (_hasTimedOut) {
            print('⏱️  Timeout waiting for auth, forcing to AuthScreen');
            _showLoginAnimation = false;
            _lastAuthenticatedUserId = null;
            print('➡️  Returning AuthScreen (timeout)');
            return const AuthScreen();
          }
          print('⏳ Waiting for auth state, showing SplashScreen');
          return const SplashScreen();
        }

        // CRITICAL: Only show home screen if we have authenticated user data
        if (snapshot.hasData && snapshot.data != null) {
          final currentUserId = snapshot.data!.uid;
          final currentEmail = snapshot.data!.email;
          print('✅ User authenticated: $currentEmail (ID: $currentUserId)');

          // Check if this is a new user (different from last time or first login)
          if (_lastAuthenticatedUserId != currentUserId) {
            print('🎬 New user detected, showing login animation');
            print('   Previous user ID: $_lastAuthenticatedUserId');
            print('   Current user ID: $currentUserId');
            _lastAuthenticatedUserId = currentUserId;
            _showLoginAnimation = true;
            print('➡️  Returning LoginSuccessScreen');
            return const LoginSuccessScreen();
          }

          // If we've already shown the animation for this user, go to home
          if (_showLoginAnimation) {
            print('✨ Animation already shown, resetting flag');
            _showLoginAnimation = false;
          }

          print('🏠 Returning HomeScreen');
          return const HomeScreen();
        } else {
          // No authenticated user - redirect to auth screen
          print('🚪 No authenticated user detected');
          print('   Resetting state variables');
          _showLoginAnimation = false;
          _lastAuthenticatedUserId = null;
          print('➡️  Returning AuthScreen (signed out)');
          return const AuthScreen();
        }
      },
    );
  }
}
