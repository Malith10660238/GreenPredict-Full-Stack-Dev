import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import '../auth/login_screen.dart';
import 'product_detail_screen.dart';
import 'create_listing_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();

  int _gridColumns = 2;
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  String _priceRange = 'All';
  String _sortBy = 'Recent';
  bool _organicOnly = false;

  final List<String> _categories = [
    'All', 'Vegetables', 'Fruits', 'Grains', 'Spices'
  ];
  final List<String> _locations = [
    'All', 'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 
    'Galle', 'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 
    'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 
    'Monaragala', 'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 
    'Ratnapura', 'Trincomalee', 'Vavuniya'
  ];
  final List<String> _priceRanges = [
    'All', 'Under Rs. 100', 'Rs. 100 - 200', 'Rs. 200 - 500', 'Above Rs. 500'
  ];
  final List<String> _sortOptions = [
    'Recent', 'Price: Low to High', 'Price: High to Low', 'Rating'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ListingProvider>(context, listen: false).loadListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _getChildAspectRatio {
    return _gridColumns == 1 ? 3.2 : 0.75;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Consumer<ListingProvider>(
            builder: (context, listingProvider, child) {
              return CustomScrollView(
                slivers: [
                  _buildProfessionalAppBar(authProvider),
                  SliverToBoxAdapter(child: _buildSearchAndControls()),
                  SliverToBoxAdapter(child: _buildFilterChips()),
                  _buildProductsGrid(authProvider, listingProvider),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated || !authProvider.isFarmer) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _showCreateListingDialog(context),
            backgroundColor: AppTheme.primaryGreen,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Listing',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalAppBar(AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      elevation: 0,
      automaticallyImplyLeading: false, // This prevents the invisible back button
      title: Text(
        'Marketplace',
        style: AppTheme.heading3.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: _showAdvancedFilters,
          tooltip: 'Filters',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: () {
            // Prevent any accidental taps in the header area
          },
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.accentGreen,
                ],
              ),
            ),
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fresh Marketplace',
                                style: AppTheme.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                'Quality produce from verified farmers',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildSearchAndControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search crops, farmers, locations...',
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: _performSearch,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildGridButton(1, Icons.view_list, 'List'),
                    _buildGridButton(2, Icons.grid_view, 'Grid'),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sort,
                      size: 18,
                      color: AppTheme.darkGray,
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: _sortBy,
                      items: _sortOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: AppTheme.bodyMedium.copyWith(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                        }
                      },
                      underline: const SizedBox(),
                      isDense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton(int columns, IconData icon, String tooltip) {
    final isSelected = _gridColumns == columns;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _gridColumns = columns),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppTheme.darkGray,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          ..._categories.map((category) => _buildFilterChip(
                category,
                _selectedCategory == category,
                () => setState(() => _selectedCategory = category),
              )),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Organic',
            _organicOnly,
            () => setState(() => _organicOnly = !_organicOnly),
            icon: Icons.eco_outlined,
          ),
          if (_selectedLocation != 'All') ...[
            const SizedBox(width: 8),
            _buildFilterChip(
              _selectedLocation,
              true,
              () => _showAdvancedFilters(),
              icon: Icons.location_on,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        avatar: icon != null
            ? Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.darkGray,
              )
            : null,
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryGreen.withOpacity(0.1),
        checkmarkColor: AppTheme.primaryGreen,
        labelStyle: AppTheme.bodyMedium.copyWith(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.darkGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.5)
                : AppTheme.mediumGray,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(AuthProvider authProvider, ListingProvider listingProvider) {
    if (listingProvider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (listingProvider.errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${listingProvider.errorMessage}',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Provider.of<ListingProvider>(context, listen: false).loadListings();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    final filteredListings = _filterAndSortListings(listingProvider.listings);
    
    if (filteredListings.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }
    
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridColumns,
          childAspectRatio: _getChildAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final listing = filteredListings[index];
            return _buildProductCard(listing, authProvider);
          },
          childCount: filteredListings.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> listing, AuthProvider authProvider) {
    final isListView = _gridColumns == 1;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              listing: listing,
              onChatTap: () => _handleChatTap(listing, authProvider),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: isListView ? _buildListItem(listing) : _buildGridItem(listing),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Consumer2<ListingProvider, AuthProvider>(
                builder: (context, provider, authProvider, _) {
                  final id = listing['id']?.toString() ?? '';
                  final fav = provider.isFavorite(id, authProvider.user?.uid);
                  return InkWell(
                    onTap: () => provider.toggleFavorite(id, authProvider.user?.uid),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                        ],
                      ),
                      child: Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? Colors.red : AppTheme.darkGray,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> listing) {
    final images = listing['images'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section - Reduced height for better content fit
        Container(
          height: 100,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Stack(
            children: [
              if (images.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildProductImage(images.first),
                )
              else
                const Center(
                  child: Icon(
                    Icons.image,
                    size: 40,
                    color: AppTheme.darkGray,
                  ),
                ),
              
              if (listing['isOrganic'] == true)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Organic',
                      style: AppTheme.caption.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
              if (images.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${images.length - 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Content section - Optimized for no overflow
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  listing['cropName']?.toString() ?? 'Unknown Crop',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Manufactured Date - Ultra compact
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 9,
                        color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        app_date.AppDateUtils.getRelativeTime(listing['manufacturedDate']),
                        style: AppTheme.caption.copyWith(
                          color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Location - Ultra compact
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 9, color: AppTheme.darkGray),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        listing['location']?.toString() ?? 'Unknown',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.darkGray,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Price and quantity - Bottom aligned
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Rs. ${listing['price']?.toString() ?? '0'}/kg',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${listing['quantity']?.toString() ?? '0'} kg',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.darkGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(dynamic imageData) {
    if (imageData is String) {
      // Check for empty or invalid strings
      if (imageData.isEmpty || imageData.trim().isEmpty) {
        return const Center(
          child: Icon(
            Icons.image,
            size: 40,
            color: AppTheme.darkGray,
          ),
        );
      }
      
      if (imageData.startsWith('http')) {
        // Network image (including Cloudinary) - use CachedNetworkImage
        return CachedNetworkImage(
          imageUrl: imageData,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(
              Icons.image,
              size: 40,
              color: AppTheme.darkGray,
            ),
          ),
        );
      } else {
        // Local file path
        final file = File(imageData);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.image,
                  size: 40,
                  color: AppTheme.darkGray,
                ),
              );
            },
          );
        } else {
          // File doesn't exist, show placeholder
          return const Center(
            child: Icon(
              Icons.image,
              size: 40,
              color: AppTheme.darkGray,
            ),
          );
        }
      }
    } else {
      // Fallback for unknown image types
      return const Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: AppTheme.darkGray,
        ),
      );
    }
  }

  Widget _buildListItem(Map<String, dynamic> listing) {
    // This part of the code had to be slightly changed to call _buildProductImage
    final images = listing['images'] as List<dynamic>? ?? [];
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: images.isNotEmpty
                  ? _buildProductImage(images.first)
                  : const Center(
                      child: Icon(Icons.image, size: 30, color: AppTheme.darkGray),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  listing['cropName']?.toString() ?? 'Unknown',
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  listing['farmerName']?.toString() ?? 'Unknown Farmer',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryGreen, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppTheme.darkGray),
                    const SizedBox(width: 2),
                    Text(
                      listing['location']?.toString() ?? 'Unknown',
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Manufactured Date - Ultra compact for list view
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 8,
                        color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        app_date.AppDateUtils.getRelativeTime(listing['manufacturedDate']),
                        style: AppTheme.caption.copyWith(
                          color: Color(app_date.AppDateUtils.getFreshnessColor(listing['manufacturedDate'])),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Rs. ${listing['price']?.toString() ?? '0'}/kg',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${listing['quantity']?.toString() ?? '0'} kg',
                style: AppTheme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... rest of your existing methods (filtering, search, etc.) remain the same

  List<Map<String, dynamic>> _filterAndSortListings(List<Map<String, dynamic>> listings) {
    List<Map<String, dynamic>> filteredListings = listings.where((listing) {
      final double price = (listing['price'] as num?)?.toDouble() ?? 0.0;
      
      if (_selectedCategory != 'All' && listing['category'] != _selectedCategory) {
        return false;
      }
      
      if (_selectedLocation != 'All' && listing['location'] != _selectedLocation) {
        return false;
      }
      
      if (_organicOnly && listing['isOrganic'] != true) {
        return false;
      }
      
      if (_priceRange != 'All') {
        switch (_priceRange) {
          case 'Under Rs. 100':
            if (price >= 100) return false;
            break;
          case 'Rs. 100 - 200':
            if (price < 100 || price > 200) return false;
            break;
          case 'Rs. 200 - 500':
            if (price < 200 || price > 500) return false;
            break;
          case 'Above Rs. 500':
            if (price <= 500) return false;
            break;
        }
      }
      
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final cropName = (listing['cropName']?.toString() ?? '').toLowerCase();
        final farmerName = (listing['farmerName']?.toString() ?? '').toLowerCase();
        final location = (listing['location']?.toString() ?? '').toLowerCase();
        
        if (!cropName.contains(query) &&
            !farmerName.contains(query) &&
            !location.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        filteredListings.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        filteredListings.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Rating':
        filteredListings.sort((a, b) {
          final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Recent':
        filteredListings.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        break;
    }
    
    return filteredListings;
  }

  void _performSearch(String query) {
    setState(() {
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.darkGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkGray.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategory = 'All';
                _selectedLocation = 'All';
                _priceRange = 'All';
                _organicOnly = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Advanced Filters',
                    style: AppTheme.heading3.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Location', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_locations.length - 1} districts',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildLocationSelector(),
                    const SizedBox(height: 20),
                    Text('Price Range', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _priceRanges.map((range) => FilterChip(
                        label: Text(range),
                        selected: _priceRange == range,
                        onSelected: (_) {
                          setState(() => _priceRange = range);
                          Navigator.pop(context);
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 30),
                    // Clear All Filters Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedLocation = 'All';
                            _priceRange = 'All';
                            _selectedCategory = 'All';
                            _organicOnly = false;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_all, color: Colors.white),
                        label: const Text('Clear All Filters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkGray,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleChatTap(Map<String, dynamic> listing, AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature coming soon!')),
    );
  }

  void _showCreateListingDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateListingScreen(),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mediumGray.withOpacity(0.5)),
      ),
      child: Autocomplete<String>(
        initialValue: _selectedLocation != 'All' 
            ? TextEditingValue(text: _selectedLocation) 
            : null,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return _locations.where((location) => location != 'All');
          }
          return _locations.where((location) {
            return location.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          setState(() => _selectedLocation = selection);
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: _selectedLocation == 'All' ? 'Search districts...' : _selectedLocation,
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
              suffixIcon: _selectedLocation != 'All' 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.darkGray),
                      onPressed: () {
                        setState(() => _selectedLocation = 'All');
                        textEditingController.clear();
                      },
                    )
                  : const Icon(Icons.arrow_drop_down, color: AppTheme.darkGray),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                setState(() => _selectedLocation = 'All');
              }
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    final isSelected = _selectedLocation == option;
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_on,
                          color: isSelected ? AppTheme.primaryGreen : AppTheme.darkGray,
                          size: 20,
                        ),
                        title: Text(
                          option,
                          style: AppTheme.bodyMedium.copyWith(
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: isSelected 
                            ? const Icon(Icons.check, color: AppTheme.primaryGreen, size: 20)
                            : null,
                        onTap: () {
                          onSelected(option);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}