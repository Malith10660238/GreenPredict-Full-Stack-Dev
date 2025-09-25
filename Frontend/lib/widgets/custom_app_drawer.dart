import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/marketplace/my_listings_screen.dart';
import '../screens/marketplace/favorites_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/ai_prediction/prediction_history_screen.dart';
import '../screens/inquiries/farmer_inquiries_screen.dart';
import '../screens/inquiries/consumer_messages_screen.dart';

class CustomAppDrawer extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final bool isFarmer;
  final bool isAuthenticated;
  
  const CustomAppDrawer({
    super.key,
    required this.onNavigateToTab,
    required this.isFarmer,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              _buildDrawerHeader(context, authProvider),
              Expanded(
                child: _buildDrawerItems(context, authProvider),
              ),
              _buildDrawerFooter(context, authProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    final profileImage = authProvider.profileImageFile;
    final isAuthenticated = authProvider.isAuthenticated;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.mediumGray.withOpacity(0.35)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: isAuthenticated 
                        ? () {
                            Navigator.pop(context);
                            // Navigate to profile tab
                            if (isFarmer) {
                              onNavigateToTab(3); // Profile is index 3 for farmers
                            } else {
                              onNavigateToTab(2); // Profile is index 2 for consumers
                            }
                          }
                        : () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      backgroundImage: isAuthenticated && profileImage != null 
                          ? FileImage(profileImage) 
                          : null,
                      child: (isAuthenticated && profileImage == null)
                          ? Text(
                              (user?.displayName?.isNotEmpty == true)
                                  ? user!.displayName![0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : (!isAuthenticated)
                              ? Icon(
                                  Icons.person_outline,
                                  color: AppTheme.primaryGreen,
                                  size: 35,
                                )
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated 
                              ? (user?.displayName ?? 'User')
                              : 'Guest User',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAuthenticated
                              ? (user?.email ?? 'user@email.com')
                              : 'Please sign in',
                          style: TextStyle(
                            color: AppTheme.darkGray,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isAuthenticated) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isFarmer ? 'Farmer' : 'Consumer',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildDrawerItems(BuildContext context, AuthProvider authProvider) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        
        // Home
        _buildDrawerItem(
          context: context,
          icon: Icons.home_outlined,
          title: 'Home',
          onTap: () {
            Navigator.pop(context);
            onNavigateToTab(0);
          },
        ),

        if (isAuthenticated) ...[
          // My Profile
          _buildDrawerItem(
            context: context,
            icon: Icons.person_outline,
            title: 'My Profile',
            onTap: () {
              Navigator.pop(context);
              if (isFarmer) {
                onNavigateToTab(3); // Profile is index 3 for farmers
              } else {
                onNavigateToTab(2); // Profile is index 2 for consumers
              }
            },
          ),

          // Farmer specific items
          if (isFarmer) ...[
            _buildDrawerItem(
              context: context,
              icon: Icons.list_alt_outlined,
              title: 'My Listings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyListingsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.favorite_outline,
              title: 'Favorites',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.psychology_outlined,
              title: 'AI Predictions',
              onTap: () {
                Navigator.pop(context);
                onNavigateToTab(1); // AI Predictions tab
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.history,
              title: 'Prediction History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PredictionHistoryScreen(onNavigateToTab: onNavigateToTab)),
                );
              },
            ),
          ],

          // Consumer specific items
          if (!isFarmer) ...[
            _buildDrawerItem(
              context: context,
              icon: Icons.favorite_outline,
              title: 'Favorites',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.store_outlined,
              title: 'Browse Marketplace',
              onTap: () {
                Navigator.pop(context);
                onNavigateToTab(1); // Marketplace tab
              },
            ),
          ],

          // Farmer specific: Inquiries (received messages)
          if (isFarmer)
            _buildDrawerItem(
              context: context,
              icon: Icons.inbox_outlined,
              title: 'Inquiries',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmerInquiriesScreen(),
                  ),
                );
              },
            ),

          // Consumer specific: Messages (sent messages)
          if (!isFarmer)
            _buildDrawerItem(
              context: context,
              icon: Icons.chat_bubble_outline,
              title: 'Messages',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConsumerMessagesScreen(),
                  ),
                );
              },
            ),

          _buildDrawerItem(
            context: context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],

        // Always show marketplace for non-authenticated users
        if (!isAuthenticated)
          _buildDrawerItem(
            context: context,
            icon: Icons.store_outlined,
            title: 'Marketplace',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
              );
            },
          ),

        const SizedBox(height: 6),
        _buildDrawerItem(
          context: context,
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isLogout = title.toLowerCase() == 'log out' || title.toLowerCase() == 'logout';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.redAccent : AppTheme.primaryGreen.withOpacity(0.85),
          size: 24,
        ),
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.redAccent : AppTheme.textDark,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, AuthProvider authProvider) {
    // Always reserve footer for the final action to ensure it is last
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isAuthenticated
          ? _buildDrawerItem(
              context: context,
              icon: Icons.logout,
              title: 'Log Out',
              onTap: () => _showLogoutDialog(context, authProvider),
            )
          : _buildDrawerItem(
              context: context,
              icon: Icons.login,
              title: 'Sign In',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Out',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}