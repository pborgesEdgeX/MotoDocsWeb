import 'package:flutter/material.dart';

void main() {
  runApp(const ButtonTestApp());
}

class ButtonTestApp extends StatelessWidget {
  const ButtonTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ButtonTestHomePage(),
    );
  }
}

class ButtonTestHomePage extends StatefulWidget {
  const ButtonTestHomePage({super.key});

  @override
  State<ButtonTestHomePage> createState() => _ButtonTestHomePageState();
}

class _ButtonTestHomePageState extends State<ButtonTestHomePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _lastAction = 'Ready to test...';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onButtonClick(String action) {
    print('BUTTON TEST: $action clicked');
    setState(() {
      _lastAction = '$action clicked at ${DateTime.now().toIso8601String()}';
    });

    // Show snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action button clicked!')));
  }

  void _onSignInClick() {
    print('BUTTON TEST: Sign In button clicked');
    print('BUTTON TEST: Email: ${_emailController.text}');
    print('BUTTON TEST: Password: ${_passwordController.text}');

    setState(() {
      _lastAction = 'Sign In clicked - Email: ${_emailController.text}';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sign In button clicked!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Button Click Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Button Click Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _onSignInClick,
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _onButtonClick('Test Button 1'),
              child: const Text('Test Button 1'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _onButtonClick('Test Button 2'),
              child: const Text('Test Button 2'),
            ),
            const SizedBox(height: 20),

            Text(
              'Last Action: $_lastAction',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


