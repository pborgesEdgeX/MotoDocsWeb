import 'package:flutter/material.dart';

void main() {
  runApp(const TabTestApp());
}

class TabTestApp extends StatelessWidget {
  const TabTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tab Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TabTestHomePage(),
    );
  }
}

class TabTestHomePage extends StatefulWidget {
  const TabTestHomePage({super.key});

  @override
  State<TabTestHomePage> createState() => _TabTestHomePageState();
}

class _TabTestHomePageState extends State<TabTestHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    super.dispose();
  }

  void _onButtonClick(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action button clicked! Tab: ${_tabController.index}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tab Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tab Header
              Text(
                _tabController.index == 0 ? 'Sign In Form' : 'Sign Up Form',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Form Content
              _tabController.index == 0 ? _buildSignInForm() : _buildSignUpForm(),
              
              const SizedBox(height: 20),
              
              // Tab Switching Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _tabController.animateTo(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tabController.index == 0 ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _tabController.animateTo(1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tabController.index == 1 ? Colors.blue : Colors.grey,
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
    );
  }

  Widget _buildSignInForm() {
    return Column(
      children: [
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
          onPressed: () => _onButtonClick('Sign In'),
          child: const Text('Sign In'),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
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
          onPressed: () => _onButtonClick('Sign Up'),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}







