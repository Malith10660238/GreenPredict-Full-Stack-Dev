import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static Widget _buildFavoriteImage(Map<String, dynamic> item) {
    final images = item['images'] as List?;
    
    if (images == null || images.isEmpty) {
      // Show default icon if no images
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
        ),
        child: const Icon(Icons.eco, color: AppTheme.primaryGreen),
      );
    }
    
    final firstImagePath = images.first.toString();
    
    // Check for empty or invalid strings
    if (firstImagePath.isEmpty || firstImagePath.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
        ),
        child: const Icon(Icons.eco, color: AppTheme.primaryGreen),
      );
    }
    
    // Check if it's a local file path or network URL
    if (firstImagePath.startsWith('/') || firstImagePath.startsWith('file://')) {
      // Local file - use Image.file
      return Image.file(
        File(firstImagePath),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
            ),
            child: const Icon(Icons.eco, color: AppTheme.primaryGreen),
          );
        },
      );
    } else {
      // Network URL - use CachedNetworkImage
      return CachedNetworkImage(
        imageUrl: firstImagePath,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
            ),
            child: const Icon(Icons.eco, color: AppTheme.primaryGreen),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: const BackButton(),
      ),
      body: Consumer2<ListingProvider, AuthProvider>(
        builder: (context, provider, authProvider, _) {
          final favs = provider.getFavoritesForUser(authProvider.user?.uid);
          if (favs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppTheme.darkGray.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text('No favorites yet', style: AppTheme.heading3.copyWith(color: AppTheme.darkGray)),
                  const SizedBox(height: 6),
                  Text('Tap the heart on items to add them here', style: AppTheme.caption),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadListings();
            },
            color: AppTheme.primaryGreen,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = favs[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(listing: item, onChatTap: () {}),
                      ),
                    );
                  },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildFavoriteImage(item),
                      ),
                    ),
                    title: Text(item['cropName']?.toString() ?? 'Item', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Rs. ${item['price']}/kg • ${item['location']}', style: AppTheme.caption),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        Provider.of<ListingProvider>(context, listen: false).toggleFavorite(item['id'] as String, authProvider.user?.uid);
                      },
                    ),
                  ),
                ),
              );
            },
            ),
          );
        },
      ),
    );
  }
}


