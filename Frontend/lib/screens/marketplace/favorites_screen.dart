import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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

          return ListView.separated(
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
                        color: AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco, color: AppTheme.primaryGreen),
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
          );
        },
      ),
    );
  }
}


