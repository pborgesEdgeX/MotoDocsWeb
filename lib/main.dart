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
        print(
          'DEBUG: AuthWrapper - Auth state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}',
        );

        // If there's an error, show auth screen immediately
        if (snapshot.hasError) {
          print('Auth error: ${snapshot.error}');
          _showLoginAnimation = false;
          return const AuthScreen();
        }

        // If still waiting for auth state, show splash (but with timeout)
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If we've timed out waiting for auth, force to auth screen
          if (_hasTimedOut) {
            print(
              'DEBUG: AuthWrapper - Timed out waiting for auth, forcing to AuthScreen',
            );
            _showLoginAnimation = false;
            return const AuthScreen();
          }
          return const SplashScreen();
        }

        // CRITICAL: Only show home screen if we have authenticated user data
        if (snapshot.hasData && snapshot.data != null) {
          print(
            'DEBUG: AuthWrapper - User authenticated: ${snapshot.data!.email}',
          );

          // Show login animation only on first login
          if (!_showLoginAnimation) {
            _showLoginAnimation = true;
            return const LoginSuccessScreen();
          }

          return const HomeScreen();
        } else {
          // No authenticated user - redirect to auth screen
          print(
            'DEBUG: AuthWrapper - No authenticated user, redirecting to AuthScreen',
          );
          _showLoginAnimation = false;
          return const AuthScreen();
        }
      },
    );
  }
}
