import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/profile_widgets.dart';
import '../notifications/notifications_screen.dart';
import 'guest_profile_screen.dart';
import 'edit_preferences_screen.dart';
import 'edit_crops_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Page controllers for statistics
  PageController? _farmerStatsController;
  PageController? _consumerStatsController;
  
  // Current page indices
  int _farmerCurrentPage = 0;
  int _consumerCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Initialize page controllers
    _farmerStatsController = PageController(viewportFraction: 0.85);
    _consumerStatsController = PageController(viewportFraction: 0.85);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _farmerStatsController?.dispose();
    _consumerStatsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is a guest (not authenticated)
        if (authProvider.isGuest) {
          return const GuestProfileScreen();
        }

        // Debug logging for consumer profile updates
        print('🔵 Profile screen rebuild - User type: ${authProvider.user?.userType}');
        print('🔵 Profile screen rebuild - Display name: ${authProvider.user?.displayName}');
        print('🔵 Profile screen rebuild - First name: ${authProvider.user?.firstName}');
        print('🔵 Profile screen rebuild - Last name: ${authProvider.user?.lastName}');
        print('🔵 Profile screen rebuild - Phone: ${authProvider.user?.phone}');
        print('🔵 Profile screen rebuild - Location: ${authProvider.user?.location}');
        print('🔵 Profile screen rebuild - Bio: ${authProvider.user?.bio}');
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.2),
                  AppTheme.primaryGreen.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(authProvider),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
                      child: Column(
                        children: [
                          // Welcome Section
                          _buildWelcomeSection(authProvider),
                          const SizedBox(height: 20),
                          
                          // Bio Section
                          if (authProvider.user?.bio != null) ...[
                            ProfileBioCard(
                              bio: authProvider.user!.bio!,
                              onEdit: () => _showEditBioDialog(context, authProvider),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Stats Section
                          if (authProvider.isFarmer)
                            _buildFarmerStats(context, authProvider)
                          else
                            _buildConsumerStats(context, authProvider),
                          
                          const SizedBox(height: 24),
                          
                          // Profile Information
                          _buildProfileInfo(context, authProvider),
                          
                          const SizedBox(height: 24),
                          
                          // Settings
                          _buildSettingsCard(context, authProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
            ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
    final user = authProvider.user!;
    final isFarmer = user.userType == 'farmer';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFarmer
              ? [
                  AppTheme.primaryGreen.withOpacity(0.1),
                  AppTheme.accentGreen.withOpacity(0.05),
                ]
              : [
                  AppTheme.primaryGreen.withOpacity(0.1),
                  AppTheme.accentGreen.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.2),
                  AppTheme.accentGreen.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isFarmer ? Icons.agriculture : Icons.shopping_bag,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFarmer ? 'Welcome to your Farm Dashboard' : 'Welcome to your Shopping Profile',
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFarmer 
                      ? 'Manage your farm, track sales, and grow your business'
                      : 'Track your orders, discover fresh produce, and support local farmers',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkGray,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
Widget _buildSliverAppBar(AuthProvider authProvider) {
  final user = authProvider.user;
  final profileImage = authProvider.profileImageFile;
  final profileImageUrl = authProvider.profileImageUrl;
  final isFarmer = user?.userType == 'farmer';
  
  // Debug logging
  print('🔵 Profile screen - User: $user');
  print('🔵 Profile screen - Display name: ${user?.displayName}');
  print('🔵 Profile screen - First name: ${user?.firstName}');
  print('🔵 Profile screen - Last name: ${user?.lastName}');
  print('🔵 Profile screen - Profile image file: $profileImage');
  print('🔵 Profile screen - Profile image URL: $profileImageUrl');

  return SliverAppBar(
    expandedHeight: 260.0,
    floating: false,
    pinned: true,
    backgroundColor: isFarmer ? AppTheme.primaryGreen : AppTheme.accentGreen,
    elevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      centerTitle: true,
      titlePadding: const EdgeInsets.only(bottom: 8.0),
      title: Text(
        user?.displayName ?? 'User Name',
        style: AppTheme.heading3.copyWith(
          color: Colors.white, 
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      background: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isFarmer
                    ? [
                        AppTheme.primaryGreen,
                        AppTheme.darkGreen,
                        AppTheme.accentGreen,
                      ]
                    : [
                        AppTheme.primaryGreen,
                        AppTheme.darkGreen,
                        AppTheme.accentGreen,
                      ],
              ),
            ),
          ),
          // Enhanced decorative elements
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          Builder(
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        // Outer ring with gradient
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        // Profile image
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => _showImageOptions(context, authProvider),
                            child: Container(
                              width: 114,
                              height: 114,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: profileImage != null 
                                    ? FileImage(profileImage) 
                                    : (profileImageUrl != null 
                                        ? NetworkImage(profileImageUrl) as ImageProvider
                                        : null),
                                child: (profileImage == null && profileImageUrl == null)
                                    ? Icon(
                                        isFarmer ? Icons.agriculture : Icons.shopping_bag,
                                        size: 50, 
                                        color: Colors.white.withOpacity(0.8),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        // Camera button
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryGreen,
                                  AppTheme.darkGreen,
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () => _showImageOptions(context, authProvider),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        // Status indicator
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isFarmer ? Colors.orange : Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFarmer ? Icons.agriculture : Icons.shopping_cart,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user?.email ?? 'user@email.com',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Enhanced user type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFarmer ? Icons.agriculture : Icons.shopping_bag,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFarmer ? 'Farmer' : 'Consumer',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showImageOptions(BuildContext context, AuthProvider authProvider) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppTheme.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Profile Picture',
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.photo_library,
                color: AppTheme.primaryGreen,
              ),
            ),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              await authProvider.pickProfileImage();
              
              // Show success message if image was uploaded
              if (context.mounted && authProvider.profileImageUrl != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile picture saved successfully!'),
                    backgroundColor: AppTheme.primaryGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          if (authProvider.profileImageFile != null)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
              title: const Text('Remove Picture'),
              onTap: () {
                Navigator.pop(context);
                _showRemoveImageConfirmation(context, authProvider);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

  void _showRemoveImageConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Profile Picture',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to remove your profile picture?'),
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
              Navigator.pop(context);
              await authProvider.removeProfileImage();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile picture removed'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFarmerStats(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user!;
    
    // Ensure controller is initialized
    if (_farmerStatsController == null) {
      _farmerStatsController = PageController(viewportFraction: 0.85);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernProfileSectionHeader(
          title: 'Farm Statistics',
          subtitle: 'Your farming journey at a glance',
          isFarmer: true,
        ),
        SizedBox(
          height: 320,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _farmerStatsController!,
                  itemCount: 4,
                  onPageChanged: (index) {
                    setState(() {
                      _farmerCurrentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final stats = [
                      {
                        'title': 'Active Listings',
                        'value': '${user.totalListings ?? 0}',
                        'icon': Icons.storefront,
                        'color': AppTheme.primaryGreen,
                      },
                      {
                        'title': 'Total Sales',
                        'value': '${user.totalSales ?? 0}',
                        'icon': Icons.shopping_cart,
                        'color': AppTheme.accentGreen,
                      },
                      {
                        'title': 'Farm Size',
                        'value': user.farmSize ?? 'N/A',
                        'icon': Icons.landscape,
                        'color': AppTheme.primaryGreen,
                      },
                      {
                        'title': 'Farming Experience',
                        'value': user.farmingExperience ?? 'N/A',
                        'icon': Icons.timeline,
                        'color': AppTheme.accentGreen,
                      },
                    ];
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildModernFarmerStatsCard(
                        title: stats[index]['title'] as String,
                        value: stats[index]['value'] as String,
                        icon: stats[index]['icon'] as IconData,
                        color: stats[index]['color'] as Color,
                        index: index,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _farmerCurrentPage 
                          ? AppTheme.primaryGreen 
                          : AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // My Crops Section - Always show for farmers
        if (user.userType == 'farmer') ...[
          // Debug logging
          Builder(
            builder: (context) {
              print('🔵 ProfileScreen - User crops: ${user.crops}');
              print('🔵 ProfileScreen - Crops is not null: ${user.crops != null}');
              print('🔵 ProfileScreen - Crops is not empty: ${user.crops?.isNotEmpty ?? false}');
              return const SizedBox.shrink();
            },
          ),
          ModernProfileSectionHeader(
            title: 'My Crops',
            subtitle: 'Crops you cultivate',
            isFarmer: true,
            action: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditCropsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.lightGreen.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: user.crops != null && user.crops!.isNotEmpty
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: user.crops!.map((crop) => ModernCropTag(
                      crop: crop,
                      icon: Icons.eco,
                      isFarmer: true,
                    )).toList(),
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: 48,
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No crops added yet',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the edit button to add your crops',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
        // Certification
        if (user.certification != null) ...[
          const SizedBox(height: 20),
          ProfileInfoCard(
            title: 'Certification',
            subtitle: user.certification,
            icon: Icons.verified,
            iconColor: Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildConsumerStats(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user!;
    
    // Ensure controller is initialized
    if (_consumerStatsController == null) {
      _consumerStatsController = PageController(viewportFraction: 0.85);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernProfileSectionHeader(
          title: 'Shopping Statistics',
          subtitle: 'Your shopping journey',
          isFarmer: false,
        ),
        SizedBox(
          height: 320,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _consumerStatsController!,
                  itemCount: 4,
                  onPageChanged: (index) {
                    setState(() {
                      _consumerCurrentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final stats = [
                      {
                        'title': 'Orders Placed',
                        'value': '${user.totalOrders ?? 0}',
                        'icon': Icons.shopping_bag,
                        'color': AppTheme.primaryGreen,
                      },
                      {
                        'title': 'Total Spent',
                        'value': 'Rs. ${user.totalSpent?.toStringAsFixed(0) ?? '0'}',
                        'icon': Icons.account_balance_wallet,
                        'color': AppTheme.accentGreen,
                      },
                      {
                        'title': 'Member Since',
                        'value': user.joinDate != null 
                            ? '${DateTime.now().difference(user.joinDate!).inDays ~/ 30} months'
                            : 'N/A',
                        'icon': Icons.calendar_today,
                        'color': AppTheme.primaryGreen,
                      },
                      {
                        'title': 'Avg. Order Value',
                        'value': user.totalOrders != null && user.totalOrders! > 0
                            ? 'Rs. ${(user.totalSpent! / user.totalOrders!).toStringAsFixed(0)}'
                            : 'Rs. 0',
                        'icon': Icons.trending_up,
                        'color': AppTheme.accentGreen,
                      },
                    ];
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildModernConsumerStatsCard(
                        title: stats[index]['title'] as String,
                        value: stats[index]['value'] as String,
                        icon: stats[index]['icon'] as IconData,
                        color: stats[index]['color'] as Color,
                        index: index,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _consumerCurrentPage 
                          ? AppTheme.primaryGreen 
                          : AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        // Preferences - Always show for consumers
        if (user.userType == 'consumer') ...[
          const SizedBox(height: 20),
          ModernProfileSectionHeader(
            title: 'Shopping Preferences',
            subtitle: 'What you love',
            isFarmer: false,
            action: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditPreferencesScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.lightGreen.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: user.preferences != null && user.preferences!.isNotEmpty
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: user.preferences!.map((pref) => ModernCropTag(
                      crop: pref,
                      icon: Icons.favorite,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      textColor: AppTheme.darkGreen,
                      isFarmer: false,
                    )).toList(),
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 48,
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No preferences yet',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the edit button to add your preferences',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Profile Information',
          subtitle: 'Your account details',
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ProfileInfoCard(
                title: 'Email',
                subtitle: user.email ?? 'Not set',
                icon: Icons.email,
              ),
              ProfileInfoCard(
                title: 'Phone',
                subtitle: user.phone ?? 'Not set',
                icon: Icons.phone,
              ),
              ProfileInfoCard(
                title: 'Location',
                subtitle: user.location ?? 'Not set',
                icon: Icons.location_on,
              ),
              if (user.userType == 'farmer') ...[
                ProfileInfoCard(
                  title: 'Farm Name',
                  subtitle: user.farmName ?? 'Not set',
                  icon: Icons.home_work,
                ),
                ProfileInfoCard(
                  title: 'Farm Size',
                  subtitle: user.farmSize ?? 'Not set',
                  icon: Icons.landscape,
                ),
                ProfileInfoCard(
                  title: 'Farming Experience',
                  subtitle: user.farmingExperience ?? 'Not set',
                  icon: Icons.timeline,
                ),
                if (user.certification != null)
                  ProfileInfoCard(
                    title: 'Certification',
                    subtitle: user.certification!,
                    icon: Icons.verified,
                    iconColor: Colors.green,
                  ),
              ],
              if (user.userType == 'consumer') ...[
                ProfileInfoCard(
                  title: 'Member Since',
                  subtitle: user.joinDate != null 
                      ? '${DateTime.now().difference(user.joinDate!).inDays ~/ 30} months ago'
                      : 'Not available',
                  icon: Icons.calendar_today,
                ),
                if (user.totalOrders != null && user.totalOrders! > 0)
                  ProfileInfoCard(
                    title: 'Total Orders',
                    subtitle: '${user.totalOrders} orders',
                    icon: Icons.shopping_bag,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Settings & More',
          subtitle: 'Manage your account',
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your name, contact info, and ${authProvider.isFarmer ? 'farm details' : 'preferences'}',
                onTap: () => _showEditProfileDialog(context, authProvider),
              ),
              _buildModernDivider(),
              if (authProvider.isFarmer) ...[
                _buildSettingsTile(
                  icon: Icons.eco,
                  title: 'Crop Management',
                  subtitle: 'Add or edit your crops',
                  onTap: () {},
                ),
                _buildModernDivider(),
              ],
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              _buildModernDivider(),
              _buildSettingsTile(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {},
              ),
              _buildModernDivider(),
              _buildSettingsTile(
                icon: Icons.lock_reset,
                title: 'Reset Password',
                subtitle: 'Change your account password',
                onTap: () => _showPasswordResetDialog(context, authProvider),
              ),
              _buildModernDivider(),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About Green Predict',
                subtitle: 'App version and information',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AboutDialog(
                      applicationName: 'Green Predict',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2025 Green Predict',
                    ),
                  );
                },
              ),
              _buildModernDivider(),
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                color: Colors.red.shade600,
                onTap: () => _showLogoutDialog(context, authProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryGreen).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color ?? AppTheme.primaryGreen,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: color ?? AppTheme.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkGray,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color ?? AppTheme.darkGray,
      ),
    );
  }

  Widget _buildModernDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.primaryGreen.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user!;
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final phoneController = TextEditingController(text: user.phone);
    final locationController = TextEditingController(text: user.location);
    final bioController = TextEditingController(text: user.bio);
    final farmNameController = TextEditingController(text: user.farmName);
    final farmSizeController = TextEditingController(text: user.farmSize);
    final experienceController = TextEditingController(text: user.farmingExperience);
    final certificationController = TextEditingController(text: user.certification);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: AppTheme.heading3.copyWith(color: AppTheme.primaryGreen),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'Tell us about yourself...',
                ),
              ),
              if (user.userType == 'farmer') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: farmNameController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Name',
                    prefixIcon: Icon(Icons.home_work),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: farmSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Size',
                    prefixIcon: Icon(Icons.landscape),
                    hintText: 'e.g., 5 acres',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: experienceController,
                  decoration: const InputDecoration(
                    labelText: 'Farming Experience',
                    prefixIcon: Icon(Icons.timeline),
                    hintText: 'e.g., 15 years',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: certificationController,
                  decoration: const InputDecoration(
                    labelText: 'Certification',
                    prefixIcon: Icon(Icons.verified),
                    hintText: 'e.g., Organic Certified',
                  ),
                ),
              ],
            ],
          ),
        ),
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
              await authProvider.updateUserProfile(
                displayName: '${firstNameController.text} ${lastNameController.text}',
                phone: phoneController.text,
                location: locationController.text,
                bio: bioController.text,
                farmName: farmNameController.text,
                farmSize: farmSizeController.text,
                farmingExperience: experienceController.text,
                certification: certificationController.text,
                profileImage: authProvider.profileImageFile,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditBioDialog(BuildContext context, AuthProvider authProvider) {
    final bioController = TextEditingController(text: authProvider.user?.bio);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Bio',
          style: AppTheme.heading3.copyWith(color: AppTheme.primaryGreen),
        ),
        content: TextField(
          controller: bioController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'About You',
            hintText: 'Tell us about yourself...',
            prefixIcon: Icon(Icons.info_outline),
          ),
        ),
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
              await authProvider.updateUserProfile(
                displayName: authProvider.user!.displayName!,
                phone: authProvider.user!.phone ?? '',
                location: authProvider.user!.location ?? '',
                bio: bioController.text,
                profileImage: authProvider.profileImageFile,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bio updated successfully!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context, AuthProvider authProvider) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Reset Password',
            style: AppTheme.heading3.copyWith(color: AppTheme.primaryGreen),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureNewPassword = !obscureNewPassword),
                    ),
                    hintText: 'At least 6 characters',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                  ),
                ),
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: AppTheme.bodyMedium.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                authProvider.clearError();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, child) => ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passwords do not match'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  final success = await auth.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                },
                child: auth.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: AppTheme.heading3),
        content: Text('Are you sure you want to logout?', style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Widget _buildModernFarmerStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      value,
                      style: AppTheme.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernConsumerStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      value,
                      style: AppTheme.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}