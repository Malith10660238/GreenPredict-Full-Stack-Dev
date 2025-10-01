import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? listingId;
  final Map<String, dynamic>? listing;
  final VoidCallback? onChatTap;
  
  const ProductDetailScreen({
    super.key,
    this.listingId,
    this.listing,
    this.onChatTap,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _imageController = PageController();
  final ApiService _apiService = ApiService();
  int _currentImageIndex = 0;

  Map<String, dynamic>? _currentListing;
  List<Map<String, dynamic>> _otherProducts = [];
  bool _isLoadingOtherProducts = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Set current listing
    if (widget.listing != null) {
      _currentListing = widget.listing;
    } else if (widget.listingId != null) {
      // Fetch listing by ID if needed
      try {
        final listing = await _apiService.getListingById(widget.listingId!);
        if (listing != null) {
          _currentListing = listing;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to load listing: $e';
        });
        return;
      }
    }

    if (_currentListing != null) {
      await _loadOtherProducts();
    }
  }

  Future<void> _loadOtherProducts() async {
    if (_currentListing == null) return;

    setState(() {
      _isLoadingOtherProducts = true;
      _errorMessage = null;
    });

    try {
      final farmerId = _currentListing!['farmerId'] ?? _currentListing!['farmer_id'];
      if (farmerId != null) {
        final otherProducts = await _apiService.getFarmerListings(farmerId.toString());
        
        // Filter out the current listing
        _otherProducts = otherProducts.where((product) {
          final productId = product['id'] ?? product['listingId'];
          final currentId = _currentListing!['id'] ?? _currentListing!['listingId'];
          return productId != currentId;
        }).toList();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load other products: $e';
      });
    } finally {
      setState(() {
        _isLoadingOtherProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load product',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _initializeData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentListing == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildImageGalleryAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProductHeader(),
                const SizedBox(height: 24),
                _buildFarmerInfo(),
                const SizedBox(height: 24),
                _buildProductDescription(),
                const SizedBox(height: 24),
                _buildProductDetails(),
                const SizedBox(height: 24),
                _buildOtherProducts(),
                const SizedBox(height: 100), // Space for floating button
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildChatButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildImageGalleryAppBar() {
    final images = _currentListing!['images'] as List<dynamic>? ?? [];
    
    // Debug logging for main product images
    print('🔵 Main Product Images: $images');
    print('🔵 Main Product Images Length: ${images.length}');
    if (images.isNotEmpty) {
      print('🔵 First Image: ${images.first}');
      for (int i = 0; i < images.length; i++) {
        print('🔵 Image $i: ${images[i]}');
      }
    }
    
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Consumer2<ListingProvider, AuthProvider>(
          builder: (context, listingProvider, authProvider, child) {
            final listingId = _currentListing!['id']?.toString() ?? '';
            final isFavorite = listingProvider.isFavorite(listingId, authProvider.user?.uid);
            
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  listingProvider.toggleFavorite(listingId, authProvider.user?.uid);
                  
                  // Show feedback to user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite 
                            ? 'Removed from favorites' 
                            : 'Added to favorites',
                      ),
                      backgroundColor: isFavorite ? Colors.orange : AppTheme.primaryGreen,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            if (images.isNotEmpty)
              PageView.builder(
                controller: _imageController,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageData = images[index];
                  final imageUrl = imageData != null ? imageData.toString() : null;
                  print('🔵 Main Gallery - Index $index: $imageUrl');
                  return _buildProductImage(imageUrl, [imageData]);
                },
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: AppTheme.mediumGray,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No Images Available',
                        style: TextStyle(
                          color: AppTheme.mediumGray,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _currentListing!['cropName']?.toString() ?? 'Product Name',
                style: AppTheme.heading2.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Consumer2<ListingProvider, AuthProvider>(
                  builder: (context, listingProvider, authProvider, child) {
                    final listingId = _currentListing!['id']?.toString() ?? '';
                    final isFavorite = listingProvider.isFavorite(listingId, authProvider.user?.uid);
                    
                    return GestureDetector(
                      onTap: () {
                        listingProvider.toggleFavorite(listingId, authProvider.user?.uid);
                        
                        // Show feedback to user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorite 
                                  ? 'Removed from favorites' 
                                  : 'Added to favorites',
                            ),
                            backgroundColor: isFavorite ? Colors.orange : AppTheme.primaryGreen,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFavorite ? Colors.red.withOpacity(0.1) : AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFavorite ? Colors.red : AppTheme.mediumGray,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : AppTheme.darkGray,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs. ${_currentListing!['price']?.toString() ?? '0'}/kg',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_currentListing!['quantity']?.toString() ?? '0'} kg available',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Manufactured Date - Prominently displayed
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(app_date.AppDateUtils.getFreshnessColor(_currentListing!['manufacturedDate'])).withOpacity(0.1),
                Color(app_date.AppDateUtils.getFreshnessColor(_currentListing!['manufacturedDate'])).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(app_date.AppDateUtils.getFreshnessColor(_currentListing!['manufacturedDate'])).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(app_date.AppDateUtils.getFreshnessColor(_currentListing!['manufacturedDate'])).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule,
                  color: Color(app_date.AppDateUtils.getFreshnessColor(_currentListing!['manufacturedDate'])),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manufactured Date',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.darkGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app_date.AppDateUtils.getRelativeTime(_currentListing!['manufacturedDate']),
                      style: AppTheme.heading3.copyWith(
                        color: Color(app_date.AppDateUtils.getFreshnessColor(_currentListing!['manufacturedDate'])),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      app_date.AppDateUtils.formatDate(_currentListing!['manufacturedDate']),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.darkGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(app_date.AppDateUtils.getFreshnessColor(_currentListing!['manufacturedDate'])),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  app_date.AppDateUtils.getFreshnessStatus(_currentListing!['manufacturedDate']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: AppTheme.darkGray, size: 16),
            const SizedBox(width: 4),
            Text(
              _currentListing!['location']?.toString() ?? 'Location',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
            ),
          ],
        ),
        if (_currentListing!['isOrganic'] == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentGreen),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, color: AppTheme.accentGreen, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Certified Organic',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFarmerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(
              (_currentListing!['farmerName']?.toString() ?? 'F')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentListing!['farmerName']?.toString() ?? 'Farmer Name',
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified Farmer',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Member since 2023',
                      style: AppTheme.caption.copyWith(color: AppTheme.darkGray),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          _currentListing!['description']?.toString() ?? 
          'Fresh, high-quality produce grown with care using sustainable farming practices. Harvested at peak freshness to ensure the best taste and nutritional value.',
          style: AppTheme.bodyMedium.copyWith(height: 1.6),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDetailRow('Category', _currentListing!['category']?.toString() ?? 'Vegetable'),
              _buildDetailRow('Origin', _currentListing!['location']?.toString() ?? 'Sri Lanka'),
              _buildDetailRow('Harvest Date', 'Recent'),
              _buildDetailRow('Certification', _currentListing!['isOrganic'] == true ? 'Organic' : 'Standard'),
              _buildDetailRow('Storage', 'Keep refrigerated'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherProducts() {
    if (_isLoadingOtherProducts) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More from this Farmer',
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (_otherProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More from this Farmer (${_otherProducts.length})',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _otherProducts.length,
            itemBuilder: (context, index) {
              final product = _otherProducts[index];
              return _buildOtherProductCard(product);
            },
          ),
        ),
      ],
    );
  }
    
  Widget _buildOtherProductCard(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>? ?? [];
    String? imageUrl;
    
    // Better image URL extraction with validation
    if (images.isNotEmpty) {
      final firstImage = images.first;
      if (firstImage != null && firstImage.toString().isNotEmpty && 
          firstImage.toString().trim().isNotEmpty &&
          firstImage.toString() != 'null' && firstImage.toString() != 'undefined') {
        imageUrl = firstImage.toString();
      }
    }
    
    // Debug logging
    print('🔵 Product: ${product['cropName']} - Images: $images');
    print('🔵 Image URL: $imageUrl');
    
    // Handle local file paths - keep them for proper display
    if (imageUrl != null && imageUrl.startsWith('/data/')) {
      print('🔵 Local file path detected, will handle in _buildProductImage');
      // Don't convert to null - let _buildProductImage handle it
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              listing: product,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.mediumGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: _buildProductImage(imageUrl, images),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['cropName'] ?? 'Product',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Rs. ${(product['price'] ?? 0).toStringAsFixed(0)}/kg',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product['isOrganic'] == true) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Organic',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.primaryGreen,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl, List<dynamic> images) {
    try {
      // Debug logging
      print('🔵 _buildProductImage called with:');
      print('🔵   imageUrl: $imageUrl');
      print('🔵   images: $images');
      print('🔵   imageUrl type: ${imageUrl.runtimeType}');
      print('🔵   images length: ${images.length}');
      
      // Early validation - only for truly invalid data
      if (imageUrl == null || imageUrl.isEmpty || imageUrl.trim().isEmpty || 
          imageUrl == 'null' || imageUrl == 'undefined') {
        print('🔵 No valid image data, using placeholder immediately');
        return _buildPlaceholderImage();
      }
      
      // Only reject obvious placeholder URLs, not all URLs with 'placeholder'
      if (imageUrl.contains('placeholder_crop.jpg') || 
          imageUrl.contains('default.jpg') || 
          imageUrl.contains('missing.jpg')) {
        print('🔵 Placeholder URL detected, using placeholder');
        return _buildPlaceholderImage();
      }
    
    // Check if we have a valid network URL
    if (imageUrl.startsWith('http')) {
      print('🔵 Using CachedNetworkImage for: $imageUrl');
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildPlaceholderImage(),
          errorWidget: (context, url, error) {
            print('🔵 CachedNetworkImage failed to load: $error');
            return _buildPlaceholderImage();
          },
        ),
      );
    }
    
    // Check for local file paths
    if (images.isNotEmpty) {
      final firstImage = images.first.toString();
      print('🔵 Checking local file: $firstImage');
      if (firstImage.startsWith('/data/')) {
        print('🔵 Using local file: $firstImage');
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.file(
            File(firstImage),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('🔵 Local file failed to load: $error');
              return _buildPlaceholderImage();
            },
          ),
        );
      }
    }
    
    // If we get here, no valid image found - use placeholder
    print('🔵 No valid image found - using placeholder');
    return _buildPlaceholderImage();
    
    } catch (e) {
      print('🔵 Error in _buildProductImage: $e');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: AppTheme.mediumGray,
              size: 40,
            ),
            SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildChatButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Don't show chat button if:
        // 1. User is not authenticated
        // 2. User is a farmer (farmers can't chat with other farmers)
        // 3. User is viewing their own listing
        if (!authProvider.isAuthenticated || 
            authProvider.isFarmer || 
            authProvider.user?.uid == _currentListing!['farmerId']) {
          return const SizedBox.shrink(); // Return empty widget to hide button
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: () => _handleChatWithFarmer(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chat with Farmer',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleChatWithFarmer(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to chat with the farmer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user is a farmer (farmers can't chat with other farmers)
    if (authProvider.isFarmer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Farmers can only reply to inquiries from customers.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show inquiry dialog
    _showInquiryDialog(context);
  }

  void _showInquiryDialog(BuildContext context) {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Send Inquiry'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a message to ${_currentListing!['farmerName'] ?? 'the farmer'} about this product:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              _currentListing!['title'] ?? 'Product',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _sendInquiry(context, messageController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInquiry(BuildContext dialogContext, String message) async {
    // Use the widget's context instead of dialog context
    final mainContext = this.context;
    if (message.isEmpty) {
      print('🔵 Showing empty message warning...');
      ScaffoldMessenger.of(mainContext).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a message before sending.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      print('🔵 Empty message warning shown');
      return;
    }

    // Close dialog immediately
    Navigator.pop(dialogContext);
    
    final farmerId = _currentListing!['farmerId']?.toString();
    final productId = _currentListing!['id']?.toString();
    
    if (farmerId == null || productId == null) {
      ScaffoldMessenger.of(mainContext).showSnackBar(
        const SnackBar(
          content: Text('❌ Product information is missing. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    print('🔵 Creating inquiry for farmer: $farmerId, product: $productId');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      ScaffoldMessenger.of(mainContext).showSnackBar(
        const SnackBar(
          content: Text('❌ Please log in to send messages.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await _apiService.createInquiry(
        farmerId: farmerId,
        productId: productId,
        message: message,
        token: authProvider.authToken!,
      );

      // Show success message immediately after Firebase records the inquiry
      print('🔵 Showing success message...');
      if (mounted) {
        print('🔵 Widget is mounted, showing SnackBar');
        // Add a small delay to ensure context is stable
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            try {
              ScaffoldMessenger.of(mainContext).showSnackBar(
                const SnackBar(
                  content: Text('✅ Message sent successfully! The farmer will receive your inquiry.'),
                  backgroundColor: AppTheme.primaryGreen,
                  duration: Duration(seconds: 4),
                ),
              );
              print('🔵 Success SnackBar shown');
            } catch (e) {
              print('❌ Error showing success SnackBar: $e');
            }
          }
        });
      } else {
        print('❌ Widget not mounted, cannot show SnackBar');
      }

    } catch (e) {
      print('❌ Error sending inquiry: $e');
      print('🔵 Showing error message...');
      if (mounted) {
        print('🔵 Widget is mounted, showing error SnackBar');
        // Add a small delay to ensure context is stable
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            try {
              ScaffoldMessenger.of(mainContext).showSnackBar(
                SnackBar(
                  content: Text('❌ Failed to send message. Please try again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              print('🔵 Error SnackBar shown');
            } catch (e) {
              print('❌ Error showing error SnackBar: $e');
            }
          }
        });
      } else {
        print('❌ Widget not mounted, cannot show error SnackBar');
      }
    }
  }
}