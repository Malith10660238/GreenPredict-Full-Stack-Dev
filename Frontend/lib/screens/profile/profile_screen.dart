import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/profile_widgets.dart';
import '../notifications/notifications_screen.dart';
import 'guest_profile_screen.dart';

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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          backgroundColor: AppTheme.lightGray,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(authProvider),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Bio Section
                          if (authProvider.user?.bio != null) ...[
                            ProfileBioCard(
                              bio: authProvider.user!.bio!,
                              onEdit: () => _showEditBioDialog(context, authProvider),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Stats Section
                          if (authProvider.isFarmer)
                            _buildFarmerStats(context, authProvider)
                          else
                            _buildConsumerStats(context, authProvider),
                          
                          const SizedBox(height: 20),
                          
                          // Profile Information
                          _buildProfileInfo(context, authProvider),
                          
                          const SizedBox(height: 20),
                          
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
        );
      },
    );
  }
  
Widget _buildSliverAppBar(AuthProvider authProvider) {
  final user = authProvider.user;
  final profileImage = authProvider.profileImageFile;
  final profileImageUrl = authProvider.profileImageUrl;
  
  // Debug logging
  print('🔵 Profile screen - User: $user');
  print('🔵 Profile screen - Display name: ${user?.displayName}');
  print('🔵 Profile screen - First name: ${user?.firstName}');
  print('🔵 Profile screen - Last name: ${user?.lastName}');
  print('🔵 Profile screen - Profile image file: $profileImage');
  print('🔵 Profile screen - Profile image URL: $profileImageUrl');

  return SliverAppBar(
    expandedHeight: 320.0,
    floating: false,
    pinned: true,
    backgroundColor: AppTheme.primaryGreen,
    elevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      centerTitle: true,
      titlePadding: const EdgeInsets.only(bottom: 16.0),
      title: Text(
        user?.displayName ?? 'User Name',
        style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 18),
      ),
      background: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          ),
          // Add some decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Builder(
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showImageOptions(context, authProvider),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.white.withOpacity(0.2),
                            child: CircleAvatar(
                              radius: 57,
                              backgroundImage: profileImage != null 
                                  ? FileImage(profileImage) 
                                  : (profileImageUrl != null 
                                      ? NetworkImage(profileImageUrl) as ImageProvider
                                      : null),
                              child: (profileImage == null && profileImageUrl == null)
                                  ? const Icon(Icons.person, size: 65, color: AppTheme.white)
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () => _showImageOptions(context, authProvider),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'User Name',
                      style: AppTheme.heading2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'user@email.com',
                      style: AppTheme.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 8),
                    // User type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        user?.userType == 'farmer' ? '🌱 Farmer' : '🛒 Consumer',
                        style: AppTheme.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
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
            onPressed: () {
              Navigator.pop(context);
              authProvider.removeProfileImage();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture removed'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Farm Statistics',
          subtitle: 'Your farming journey at a glance',
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            ProfileStatsCard(
              title: 'Active Listings',
              value: '${user.totalListings ?? 0}',
              icon: Icons.storefront,
              color: AppTheme.primaryGreen,
            ),
            ProfileStatsCard(
              title: 'Total Sales',
              value: '${user.totalSales ?? 0}',
              icon: Icons.shopping_cart,
              color: AppTheme.accentGreen,
            ),
            ProfileStatsCard(
              title: 'Farm Size',
              value: user.farmSize ?? 'N/A',
              icon: Icons.landscape,
              color: Colors.orange,
            ),
            ProfileStatsCard(
              title: 'Experience',
              value: user.farmingExperience ?? 'N/A',
              icon: Icons.timeline,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Crops Section
        if (user.crops != null && user.crops!.isNotEmpty) ...[
          ProfileSectionHeader(
            title: 'Crops Grown',
            subtitle: 'Your specialty crops',
          ),
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.crops!.map((crop) => ProfileChip(
                label: crop,
                icon: Icons.eco,
              )).toList(),
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Shopping Statistics',
          subtitle: 'Your shopping journey',
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            ProfileStatsCard(
              title: 'Total Orders',
              value: '${user.totalOrders ?? 0}',
              icon: Icons.shopping_bag,
              color: AppTheme.primaryGreen,
            ),
            ProfileStatsCard(
              title: 'Total Spent',
              value: 'Rs. ${user.totalSpent?.toStringAsFixed(0) ?? '0'}',
              icon: Icons.account_balance_wallet,
              color: AppTheme.accentGreen,
            ),
            ProfileStatsCard(
              title: 'Member Since',
              value: user.joinDate != null 
                  ? '${DateTime.now().difference(user.joinDate!).inDays ~/ 30} months'
                  : 'N/A',
              icon: Icons.calendar_today,
              color: Colors.orange,
            ),
            ProfileStatsCard(
              title: 'Avg. Order',
              value: user.totalOrders != null && user.totalOrders! > 0
                  ? 'Rs. ${(user.totalSpent! / user.totalOrders!).toStringAsFixed(0)}'
                  : 'Rs. 0',
              icon: Icons.trending_up,
              color: Colors.blue,
            ),
          ],
        ),
        // Preferences
        if (user.preferences != null && user.preferences!.isNotEmpty) ...[
          const SizedBox(height: 20),
          ProfileSectionHeader(
            title: 'Shopping Preferences',
            subtitle: 'What you love',
          ),
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.preferences!.map((pref) => ProfileChip(
                label: pref,
                icon: Icons.favorite,
              )).toList(),
            ),
          ),
        ],
        // Favorite Crops
        if (user.favoriteCrops != null && user.favoriteCrops!.isNotEmpty) ...[
          const SizedBox(height: 20),
          ProfileSectionHeader(
            title: 'Favorite Crops',
            subtitle: 'Your go-to produce',
          ),
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.favoriteCrops!.map((crop) => ProfileChip(
                label: crop,
                icon: Icons.eco,
              )).toList(),
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
                title: 'Full Name',
                subtitle: user.displayName ?? 'Not set',
                icon: Icons.person,
              ),
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
              if (authProvider.isFarmer) ...[
                _buildSettingsTile(
                  icon: Icons.eco,
                  title: 'Crop Management',
                  subtitle: 'Add or edit your crops',
                  onTap: () {},
                ),
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
              _buildSettingsTile(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.lock_reset,
                title: 'Reset Password',
                subtitle: 'Change your account password',
                onTap: () => _showPasswordResetDialog(context, authProvider),
              ),
              const Divider(indent: 20, endIndent: 20),
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
              const Divider(indent: 20, endIndent: 20),
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
}