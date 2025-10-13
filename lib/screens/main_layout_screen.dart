import 'package:flutter/material.dart';
import '../widgets/sidebar_navigation.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/mechanic/mechanic_dashboard_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  String _currentRoute = '/ai-docs';

  void _handleNavigation(String route) {
    if (route == '/login') {
      Navigator.pushReplacementNamed(context, route);
      return;
    }

    setState(() {
      _currentRoute = route;
    });

    // For deeper routes, use Navigator
    if (route.startsWith('/mechanic-') && route != '/mechanic-dashboard') {
      Navigator.pushNamed(context, route);
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentRoute) {
      case '/mechanic-dashboard':
        return const MechanicDashboardScreen();
      case '/ai-docs':
      default:
        return const AIChatScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          SidebarNavigation(
            currentRoute: _currentRoute,
            onNavigate: _handleNavigation,
          ),

          // Main Content Area
          Expanded(child: _getCurrentScreen()),
        ],
      ),
    );
  }
}

