import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MotoDocsAppNoFirebase());
}

class MotoDocsAppNoFirebase extends StatelessWidget {
  const MotoDocsAppNoFirebase({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoDocs AI (No Firebase)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const AuthScreenNoFirebase(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Dummy AuthService to replace Firebase-dependent one
class DummyAuthService extends ChangeNotifier {
  Stream<bool> get authStateChanges =>
      Stream.value(false); // Always unauthenticated for this test

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('DUMMY: Sign In: $email / $password');
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    print('DUMMY: Sign in completed');
    notifyListeners();
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    print('DUMMY: Sign Up: $email / $password / $displayName');
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    print('DUMMY: Sign up completed');
    notifyListeners();
  }
}

// AuthScreen replica, but using DummyAuthService
class AuthScreenNoFirebase extends StatefulWidget {
  const AuthScreenNoFirebase({super.key});

  @override
  State<AuthScreenNoFirebase> createState() => _AuthScreenNoFirebaseState();
}

class _AuthScreenNoFirebaseState extends State<AuthScreenNoFirebase>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    print('DEBUG: _signIn method called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }
    print('DEBUG: Form validation passed');

    setState(() => _isLoading = true);
    try {
      print(
        'DEBUG: Attempting dummy sign in with email: ${_emailController.text.trim()}',
      );

      // Add timeout to prevent hanging
      await DummyAuthService()
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Sign in timed out after 30 seconds');
            },
          );

      print('DEBUG: Dummy sign in successful');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dummy Sign In Successful!')),
        );
      }
    } catch (e) {
      print('DEBUG: Sign in failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    print('DEBUG: _signUp method called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }
    print('DEBUG: Form validation passed');

    setState(() => _isLoading = true);
    try {
      print(
        'DEBUG: Attempting dummy sign up with email: ${_emailController.text.trim()}',
      );

      await DummyAuthService().createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      print('DEBUG: Dummy sign up successful');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dummy Sign Up Successful!')),
        );
      }
    } catch (e) {
      print('DEBUG: Sign up failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.indigo],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and Title
                      const Icon(
                        Icons.motorcycle,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'MotoDocs AI (No Firebase)',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AI-Powered Motorcycle Documentation',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Tab Header
                      Text(
                        _tabController.index == 0 ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form - Simplified without TabBarView
                      Form(
                        key: _formKey,
                        child: _tabController.index == 0
                            ? _buildSignInForm()
                            : _buildSignUpForm(),
                      ),

                      // Add tab switching buttons
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                print('DEBUG: Sign In button clicked');
                                _tabController.animateTo(0);
                                print(
                                  'DEBUG: Tab controller index: ${_tabController.index}',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _tabController.index == 0
                                    ? Colors.blue
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                print('DEBUG: Sign Up button clicked');
                                _tabController.animateTo(1);
                                print(
                                  'DEBUG: Tab controller index: ${_tabController.index}',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _tabController.index == 1
                                    ? Colors.blue
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofocus: false,
          enableInteractiveSelection: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          textInputAction: TextInputAction.done,
          enableInteractiveSelection: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    print('DEBUG: Sign In form button clicked');
                    _signIn();
                  },
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          enableInteractiveSelection: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enableInteractiveSelection: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          textInputAction: TextInputAction.done,
          enableInteractiveSelection: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    print('DEBUG: Sign Up form button clicked');
                    _signUp();
                  },
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Sign Up'),
          ),
        ),
      ],
    );
  }
}















