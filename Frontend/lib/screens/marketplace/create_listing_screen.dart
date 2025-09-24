import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isOrganic = false;
  String _selectedCategory = 'Vegetables';
  DateTime? _manufacturedDate;
  
  final List<String> _categories = [
    'Vegetables', 'Fruits', 'Grains', 'Spices', 'Other'
  ];

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
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('Create Listing'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Consumer2<ListingProvider, AuthProvider>(
        builder: (context, listingProvider, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(listingProvider),
                  const SizedBox(height: 24),
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildDetailsSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(listingProvider, authProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection(ListingProvider listingProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Images',
                      style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Add up to 5 high-quality images',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (listingProvider.selectedImages.isEmpty)
            _buildImagePickerArea(listingProvider)
          else
            _buildSelectedImagesGrid(listingProvider),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: listingProvider.selectedImages.length < 5 
                      ? () => listingProvider.pickImages() 
                      : null,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: listingProvider.selectedImages.length < 5 
                      ? () => listingProvider.takePhoto() 
                      : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
            ],
          ),
          
          if (listingProvider.selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${listingProvider.selectedImages.length}/5 images selected',
                    style: AppTheme.caption.copyWith(color: AppTheme.darkGray),
                  ),
                  TextButton(
                    onPressed: () => listingProvider.clearSelectedImages(),
                    child: Text(
                      'Clear All',
                      style: AppTheme.caption.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePickerArea(ListingProvider listingProvider) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(listingProvider),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.mediumGray,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 40,
                color: AppTheme.darkGray,
              ),
              SizedBox(height: 8),
              Text(
                'Tap to add images',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontSize: 14,
                ),
              ),
              Text(
                'Up to 5 images',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagesGrid(ListingProvider listingProvider) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: listingProvider.selectedImages.length + 
                     (listingProvider.selectedImages.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < listingProvider.selectedImages.length) {
              return _buildImageItem(listingProvider, index);
            } else {
              return _buildAddMoreImageButton(listingProvider);
            }
          },
        ),
      ],
    );
  }

  Widget _buildImageItem(ListingProvider listingProvider, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.mediumGray),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              listingProvider.selectedImages[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Image number indicator
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => listingProvider.removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
        
        // Primary image indicator
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Main',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoreImageButton(ListingProvider listingProvider) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(listingProvider),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.mediumGray,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: AppTheme.darkGray,
                size: 24,
              ),
              Text(
                'Add more',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _cropNameController,
            decoration: const InputDecoration(
              labelText: 'Product Name *',
              hintText: 'e.g., Fresh Tomatoes',
              prefixIcon: Icon(Icons.eco),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter product name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
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
          
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your product quality, freshness, farming methods...',
              prefixIcon: Icon(Icons.description),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Details',
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price per kg (Rs.) *',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: '150',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter valid number';
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
                    labelText: 'Quantity (kg) *',
                    prefixIcon: Icon(Icons.scale),
                    hintText: '50',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location *',
              hintText: 'City or District',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter location';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Manufactured Date Field
          GestureDetector(
            onTap: () => _selectManufacturedDate(),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Manufactured Date *',
                  hintText: _manufacturedDate != null 
                      ? '${_manufacturedDate!.day}/${_manufacturedDate!.month}/${_manufacturedDate!.year}'
                      : 'Select when product was manufactured',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  filled: _manufacturedDate != null,
                  fillColor: _manufacturedDate != null 
                      ? AppTheme.primaryGreen.withOpacity(0.1) 
                      : null,
                ),
                controller: _manufacturedDate != null 
                    ? TextEditingController(
                        text: '${_manufacturedDate!.day}/${_manufacturedDate!.month}/${_manufacturedDate!.year}'
                      )
                    : null,
                validator: (value) {
                  if (_manufacturedDate == null) {
                    return 'Please select manufactured date';
                  }
                  return null;
                },
              ),
            ),
          ),
          
          // Show selected date info if date is selected
          if (_manufacturedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manufactured Date Selected',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_manufacturedDate!.day}/${_manufacturedDate!.month}/${_manufacturedDate!.year}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _manufacturedDate = null;
                      });
                    },
                    child: Text(
                      'Change',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CheckboxListTile(
              title: const Text('Organic Product'),
              subtitle: const Text('Certified organic or naturally grown'),
              value: _isOrganic,
              onChanged: (value) {
                setState(() {
                  _isOrganic = value ?? false;
                });
              },
              activeColor: AppTheme.primaryGreen,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ListingProvider listingProvider, AuthProvider authProvider) {
    return GradientButton(
      onPressed: listingProvider.isLoading ? null : () => _submitListing(listingProvider, authProvider),
      child: listingProvider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Create Listing',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _selectManufacturedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _manufacturedDate ?? DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Max 30 days ago
      lastDate: DateTime.now(), // Cannot be future date
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _manufacturedDate) {
      setState(() {
        _manufacturedDate = picked;
      });
    }
  }

  void _showImageSourceDialog(ListingProvider listingProvider) {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.mediumGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Product Images',
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
              subtitle: const Text('Select multiple images'),
              onTap: () {
                Navigator.pop(context);
                listingProvider.pickImages();
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
              subtitle: const Text('Use camera to capture'),
              onTap: () {
                Navigator.pop(context);
                listingProvider.takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitListing(ListingProvider listingProvider, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      if (listingProvider.selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image of your product'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final listingData = {
        'cropName': _cropNameController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'quantity': double.tryParse(_quantityController.text) ?? 0,
        'location': _locationController.text.trim(),
        'isOrganic': _isOrganic,
        'manufacturedDate': _manufacturedDate?.toIso8601String(),
        'farmerName': authProvider.user?.displayName ?? 'Unknown',
        'farmerId': authProvider.user?.uid ?? 'unknown',
        'contact': authProvider.user?.phone ?? '',
      };

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
      
      await listingProvider.addListing(listingData, token);

      if (mounted) {
        if (listingProvider.errorMessage == null) {
          Navigator.pop(context);
          // Go to My Listings after creation
          Future.microtask(() {
            Navigator.pushNamed(context, '/my-listings');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing created successfully!'),
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