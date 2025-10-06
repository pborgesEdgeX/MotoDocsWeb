import 'package:flutter/material.dart';

void main() {
  runApp(const DebugStepApp());
}

class DebugStepApp extends StatelessWidget {
  const DebugStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug Step',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DebugStepHome(),
    );
  }
}

class DebugStepHome extends StatefulWidget {
  const DebugStepHome({super.key});

  @override
  State<DebugStepHome> createState() => _DebugStepHomeState();
}

class _DebugStepHomeState extends State<DebugStepHome> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _debugInfo = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Step by Step'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Debug info display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Info:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_debugInfo.isEmpty ? 'No input detected' : _debugInfo),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Simple input field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Simple)',
                border: OutlineInputBorder(),
                hintText: 'Click and type here',
              ),
              onChanged: (value) {
                setState(() {
                  _debugInfo = 'Email field: "$value"';
                });
              },
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (Simple)',
                border: OutlineInputBorder(),
                hintText: 'Click and type here',
              ),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  _debugInfo = 'Password field: "${'*' * value.length}"';
                });
              },
            ),
            const SizedBox(height: 20),

            // Test button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _debugInfo =
                      'Button clicked! Email: "${_emailController.text}", Password: "${_passwordController.text}"';
                });
              },
              child: const Text('Test Button'),
            ),
            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'If you can type in the fields above and see the debug info update, then basic Flutter web inputs work. The issue is with the complex UI structure in the main app.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
