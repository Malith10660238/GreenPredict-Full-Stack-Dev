import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';

class EditListingScreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  
  const EditListingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isOrganic = false;
  String _selectedCategory = 'Vegetables';
  
  // Track which existing images to remove
  Set<int> _imagesToRemove = {};
  
  final List<String> _categories = [
    'Vegetables', 'Fruits', 'Grains', 'Spices', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _cropNameController.text = widget.listing['cropName'] ?? '';
    _descriptionController.text = widget.listing['description'] ?? '';
    _priceController.text = widget.listing['price']?.toString() ?? '';
    _quantityController.text = widget.listing['quantity']?.toString() ?? '';
    _locationController.text = widget.listing['location'] ?? '';
    _isOrganic = widget.listing['isOrganic'] ?? false;
    _selectedCategory = widget.listing['category'] ?? 'Vegetables';
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => _handleBackButton(context),
          tooltip: 'Go back',
        ),
        actions: [
          Consumer<ListingProvider>(
            builder: (context, provider, child) {
              if (provider.selectedImages.isNotEmpty) {
                return TextButton(
                  onPressed: () => _showDiscardChangesDialog(context),
                  child: Text(
                    'Discard',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Fields
                  _buildFormCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Images Section
                  _buildImagesCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Error Message
                  Consumer<ListingProvider>(
                    builder: (context, provider, child) {
                      if (provider.errorMessage != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            provider.errorMessage!,
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Save Changes Button
                  Consumer<ListingProvider>(
                    builder: (context, provider, child) {
                      return GradientButton(
                        onPressed: provider.isLoading ? null : _saveChanges,
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Information',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Crop Name
          TextFormField(
            controller: _cropNameController,
            decoration: const InputDecoration(
              labelText: 'Crop Name',
              prefixIcon: Icon(Icons.eco),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter crop name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
              hintText: 'Describe your product...',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter description';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Price and Quantity Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (Rs.)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (kg)',
                    prefixIcon: Icon(Icons.scale),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter quantity';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid quantity';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Location
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter location';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Organic Checkbox
          CheckboxListTile(
            title: const Text('Organic Product'),
            subtitle: const Text('Check if this is an organic product'),
            value: _isOrganic,
            onChanged: (value) {
              setState(() {
                _isOrganic = value ?? false;
              });
            },
            activeColor: AppTheme.primaryGreen,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Images',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Consumer<ListingProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Current Images with Delete Option
                  if (widget.listing['images'] != null && (widget.listing['images'] as List).isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 18,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Current Product Images (${(widget.listing['images'] as List).length})',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (widget.listing['images'] as List).length,
                              itemBuilder: (context, index) {
                                final imagePath = widget.listing['images'][index];
                                final isMarkedForRemoval = _imagesToRemove.contains(index);
                                
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isMarkedForRemoval ? Colors.red : AppTheme.primaryGreen,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 120,
                                            height: 120,
                                            child: Stack(
                                              children: [
                                                _buildNetworkImageWithFallback(imagePath, 120, 120),
                                                if (isMarkedForRemoval)
                                                  Container(
                                                    width: 120,
                                                    height: 120,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.7),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.delete_forever,
                                                        color: Colors.white,
                                                        size: 32,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isMarkedForRemoval ? Colors.red : AppTheme.primaryGreen,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isMarkedForRemoval ? 'REMOVE' : 'Image ${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Delete button
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => _removeExistingImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: isMarkedForRemoval ? Colors.green : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isMarkedForRemoval ? Icons.undo : Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Show message when no existing images
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.mediumGray),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.darkGray,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This listing currently has no images. Add some images to make it more attractive to buyers.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.darkGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // New Images
                  if (provider.selectedImages.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 18,
                                color: AppTheme.accentGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'New Images to Add (${provider.selectedImages.length})',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These images will be added to your existing images:',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.darkGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: provider.selectedImages.length,
                              itemBuilder: (context, index) {
                                final image = provider.selectedImages[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.accentGreen,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.file(
                                            image,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentGreen,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'NEW ${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => provider.removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Add Images Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showImageOptions(context, provider),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            widget.listing['images'] != null && (widget.listing['images'] as List).isNotEmpty
                                ? 'Add More Images'
                                : 'Add Images',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: const BorderSide(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showImageOptions(BuildContext context, ListingProvider provider) {
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
              'Add Images',
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
              onTap: () {
                Navigator.pop(context);
                provider.pickImages();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.accentGreen,
                ),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                provider.takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackButton(BuildContext context) {
    final listingProvider = Provider.of<ListingProvider>(context, listen: false);
    
    // Check if there are any unsaved changes
    bool hasUnsavedChanges = _hasUnsavedChanges() || listingProvider.selectedImages.isNotEmpty;
    
    if (hasUnsavedChanges) {
      _showDiscardChangesDialog(context);
    } else {
      // No unsaved changes, just go back
      Navigator.pop(context);
    }
  }

  bool _hasUnsavedChanges() {
    // Check if any form fields have been modified
    bool formChanges = _cropNameController.text != (widget.listing['cropName'] ?? '') ||
           _descriptionController.text != (widget.listing['description'] ?? '') ||
           _priceController.text != (widget.listing['price']?.toString() ?? '') ||
           _quantityController.text != (widget.listing['quantity']?.toString() ?? '') ||
           _locationController.text != (widget.listing['location'] ?? '') ||
           _isOrganic != (widget.listing['isOrganic'] ?? false) ||
           _selectedCategory != (widget.listing['category'] ?? 'Vegetables');
    
    // Check if any images are marked for removal
    bool imageRemovalChanges = _imagesToRemove.isNotEmpty;
    
    return formChanges || imageRemovalChanges;
  }

  void _removeExistingImage(int index) {
    setState(() {
      if (_imagesToRemove.contains(index)) {
        _imagesToRemove.remove(index);
      } else {
        _imagesToRemove.add(index);
      }
    });
  }

  void _showDiscardChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Discard Changes?',
          style: AppTheme.heading3.copyWith(color: Colors.orange),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have unsaved changes:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Consumer<ListingProvider>(
              builder: (context, provider, child) {
                List<Widget> changeItems = [];
                
                // Check for form field changes
                if (_hasUnsavedChanges()) {
                  changeItems.add(
                    Text(
                      '• Form fields have been modified',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                
                // Check for new images
                if (provider.selectedImages.isNotEmpty) {
                  changeItems.add(
                    Text(
                      '• ${provider.selectedImages.length} new image(s) selected',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                
                // Check for images to remove
                if (_imagesToRemove.isNotEmpty) {
                  changeItems.add(
                    Text(
                      '• ${_imagesToRemove.length} image(s) marked for removal',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: changeItems,
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to discard these changes and go back?',
              style: AppTheme.bodyMedium,
            ),
          ],
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
            onPressed: () {
              // Clear selected images and go back
              final listingProvider = Provider.of<ListingProvider>(context, listen: false);
              listingProvider.clearSelectedImages();
              setState(() {
                _imagesToRemove.clear();
              });
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImageWithFallback(String imagePath, double width, double height) {
    print('🔍 Loading image: $imagePath');
    
    // Check if it's a local file path or network URL
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      // Local file - use Image.file
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Local file load error for $imagePath: $error');
          return _buildErrorPlaceholder(width, height);
        },
      );
    } else {
      // Network URL - use Image.network
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Network image load error for $imagePath: $error');
          return _buildErrorPlaceholder(width, height);
        },
      );
    }
  }

  Widget _buildErrorPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Failed to load',
            style: AppTheme.caption.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap to retry',
            style: AppTheme.caption.copyWith(
              color: AppTheme.darkGray,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final listingProvider = Provider.of<ListingProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Prepare updated data
      final updatedData = {
        'cropName': _cropNameController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'quantity': double.tryParse(_quantityController.text) ?? 0,
        'location': _locationController.text.trim(),
        'isOrganic': _isOrganic,
        'farmerName': authProvider.user?.displayName ?? 'Unknown',
        'farmerId': authProvider.user?.uid ?? 'unknown',
        'contact': authProvider.user?.phone ?? '',
      };
      

      // Combine existing images with new images, excluding removed ones
      List<String> allImages = [];
      
      // Add existing images (excluding those marked for removal)
      if (widget.listing['images'] != null) {
        List<String> existingImages = List<String>.from(widget.listing['images']);
        for (int i = 0; i < existingImages.length; i++) {
          if (!_imagesToRemove.contains(i)) {
            allImages.add(existingImages[i]);
          }
        }
      }
      
      // Add new images
      if (listingProvider.selectedImages.isNotEmpty) {
        List<String> newImagePaths = listingProvider.selectedImages.map((file) => file.path).toList();
        allImages.addAll(newImagePaths);
      }
      
      // Always update images (even if empty, to remove all images)
      updatedData['images'] = allImages;

      // Get the auth token
      String? token = authProvider.authToken;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      await listingProvider.updateListing(widget.listing['id'], updatedData, token);

      if (mounted) {
        if (listingProvider.errorMessage == null) {
          // Clear selected images and removal tracking after successful update
          listingProvider.clearSelectedImages();
          setState(() {
            _imagesToRemove.clear();
          });
          
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(listingProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
