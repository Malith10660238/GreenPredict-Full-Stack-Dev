import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onChatTap;
  
  const ProductDetailScreen({
    super.key,
    required this.listing,
    required this.onChatTap,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _imageController = PageController();
  final ApiService _apiService = ApiService();
  int _currentImageIndex = 0;

  // TODO: Fetch real farmer's other products from API
  final List<Map<String, dynamic>> _otherProducts = [];

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final images = widget.listing['images'] as List<dynamic>? ?? [];
    
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
            final listingId = widget.listing['id']?.toString() ?? '';
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
                  return _buildProductImage(images[index]);
                },
              )
            else
              Container(
                color: AppTheme.lightGray,
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 80,
                    color: AppTheme.mediumGray,
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
                widget.listing['cropName']?.toString() ?? 'Product Name',
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
                    final listingId = widget.listing['id']?.toString() ?? '';
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
              'Rs. ${widget.listing['price']?.toString() ?? '0'}/kg',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.listing['quantity']?.toString() ?? '0'} kg available',
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
                Color(app_date.AppDateUtils.getFreshnessColor(widget.listing['manufacturedDate'])).withOpacity(0.1),
                Color(app_date.AppDateUtils.getFreshnessColor(widget.listing['manufacturedDate'])).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(app_date.AppDateUtils.getFreshnessColor(widget.listing['manufacturedDate'])).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(app_date.AppDateUtils.getFreshnessColor(widget.listing['manufacturedDate'])).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule,
                  color: Color(app_date.AppDateUtils.getFreshnessColor(widget.listing['manufacturedDate'])),
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
                      app_date.AppDateUtils.getRelativeTime(widget.listing['manufacturedDate']),
                      style: AppTheme.heading3.copyWith(
                        color: Color(app_date.AppDateUtils.getFreshnessColor(widget.listing['manufacturedDate'])),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      app_date.AppDateUtils.formatDate(widget.listing['manufacturedDate']),
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
                  color: Color(app_date.AppDateUtils.getFreshnessColor(widget.listing['manufacturedDate'])),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  app_date.AppDateUtils.getFreshnessStatus(widget.listing['manufacturedDate']),
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
              widget.listing['location']?.toString() ?? 'Location',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
            ),
          ],
        ),
        if (widget.listing['isOrganic'] == true)
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
              (widget.listing['farmerName']?.toString() ?? 'F')[0].toUpperCase(),
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
                  widget.listing['farmerName']?.toString() ?? 'Farmer Name',
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
          widget.listing['description']?.toString() ?? 
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
              _buildDetailRow('Category', widget.listing['category']?.toString() ?? 'Vegetable'),
              _buildDetailRow('Origin', widget.listing['location']?.toString() ?? 'Sri Lanka'),
              _buildDetailRow('Harvest Date', 'Recent'),
              _buildDetailRow('Certification', widget.listing['isOrganic'] == true ? 'Organic' : 'Standard'),
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
    return Container(
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
              decoration: const BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, color: AppTheme.darkGray, size: 30),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['cropName'],
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Rs. ${product['price']}/kg',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(dynamic imageData) {
    if (imageData is String) {
      if (imageData.startsWith('http')) {
        // Network image
        return Image.network(
          imageData,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppTheme.lightGray,
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 80,
                  color: AppTheme.darkGray,
                ),
              ),
            );
          },
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
              return Container(
                color: AppTheme.lightGray,
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 80,
                    color: AppTheme.darkGray,
                  ),
                ),
              );
            },
          );
        } else {
          // File doesn't exist, show placeholder
          return Container(
            color: AppTheme.lightGray,
            child: const Center(
              child: Icon(
                Icons.image,
                size: 80,
                color: AppTheme.darkGray,
              ),
            ),
          );
        }
      }
    } else {
      // Fallback for unknown image types
      return Container(
        color: AppTheme.lightGray,
        child: const Center(
          child: Icon(
            Icons.image,
            size: 80,
            color: AppTheme.darkGray,
          ),
        ),
      );
    }
  }

  Widget _buildChatButton(BuildContext context) {
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
              'Send a message to ${widget.listing['farmerName'] ?? 'the farmer'} about this product:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              widget.listing['title'] ?? 'Product',
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
    
    final farmerId = widget.listing['farmerId']?.toString();
    final productId = widget.listing['id']?.toString();
    
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