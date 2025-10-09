import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mechanic_auth_service.dart';

class SidebarNavigation extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const SidebarNavigation({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final mechanicAuthService = context.watch<MechanicAuthService>();

    // Determine if user is a mechanic or regular user
    final isMechanic = mechanicAuthService.isAuthenticated;
    final userName = isMechanic
        ? (mechanicAuthService.currentMechanic?.name ?? 'Mechanic')
        : (authService.currentUser?.email?.split('@').first ?? 'User');
    final userEmail = isMechanic
        ? (mechanicAuthService.currentMechanic?.email ?? '')
        : (authService.currentUser?.email ?? '');

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade700,
                  Colors.deepOrange.shade600,
                ],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: isMechanic && mechanicAuthService.currentMechanic?.profilePhotoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            mechanicAuthService.currentMechanic!.profilePhotoUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 40, color: Colors.orange),
                          ),
                        )
                      : Icon(
                          isMechanic ? Icons.engineering : Icons.person,
                          size: 40,
                          color: Colors.orange.shade700,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isMechanic) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: mechanicAuthService.currentMechanic?.isAvailable == true
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mechanicAuthService.currentMechanic?.isAvailable == true
                          ? '🟢 Available'
                          : '🔴 Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.auto_stories,
                  title: 'AI Docs',
                  route: '/ai-docs',
                  isActive: currentRoute == '/ai-docs',
                ),
                if (isMechanic)
                  _buildNavItem(
                    context,
                    icon: Icons.calendar_month,
                    title: 'Mechanic Scheduler',
                    route: '/mechanic-dashboard',
                    isActive: currentRoute.startsWith('/mechanic'),
                  ),
              ],
            ),
          ),

          // Bottom Section
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: '/settings',
                  isActive: currentRoute == '/settings',
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _handleLogout(context, isMechanic);
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive ? Colors.orange.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onNavigate(route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.orange.shade700 : Colors.grey.shade600,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                          isActive ? Colors.orange.shade700 : Colors.grey.shade800,
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, bool isMechanic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isMechanic) {
                context.read<MechanicAuthService>().logout();
              } else {
                context.read<AuthService>().signOut();
              }
              onNavigate('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

