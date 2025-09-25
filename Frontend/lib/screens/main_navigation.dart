import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_app_drawer.dart';
import 'home/home_screen.dart';
import 'ai_prediction/ai_prediction_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // Method to change tab from drawer
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isFarmer = authProvider.isFarmer;
        final isGuest = authProvider.isGuest;

        // Different screens for farmers vs consumers vs guests
        final List<Widget> farmerScreens = [
          HomeScreen(onMenuTap: _openDrawer),
          const AIPredictionScreen(),
          const MarketplaceScreen(),
          const ProfileScreen(),
        ];

        final List<Widget> consumerScreens = [
          HomeScreen(onMenuTap: _openDrawer),
          const MarketplaceScreen(),
          const ProfileScreen(),
        ];

        final List<Widget> guestScreens = [
          HomeScreen(onMenuTap: _openDrawer),
          const MarketplaceScreen(),
          const ProfileScreen(),
        ];

        final screens = isGuest ? guestScreens : (isFarmer ? farmerScreens : consumerScreens);

        // Adjust current index if consumer switches to farmer view or vice versa
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: CustomAppDrawer(
            onNavigateToTab: changeTab,
            isFarmer: isFarmer,
            isAuthenticated: authProvider.isAuthenticated,
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.primaryGreen,
              unselectedItemColor: AppTheme.darkGray,
              selectedLabelStyle: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTheme.caption,
              items: isGuest ? _guestNavItems() : (isFarmer ? _farmerNavItems() : _consumerNavItems()),
            ),
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _farmerNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.psychology_outlined),
        activeIcon: Icon(Icons.psychology),
        label: 'AI Predict',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        activeIcon: Icon(Icons.store),
        label: 'Marketplace',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  List<BottomNavigationBarItem> _consumerNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        activeIcon: Icon(Icons.store),
        label: 'Marketplace',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  List<BottomNavigationBarItem> _guestNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        activeIcon: Icon(Icons.store),
        label: 'Marketplace',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }
}