import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';

class EditCropsScreen extends StatefulWidget {
  const EditCropsScreen({super.key});

  @override
  State<EditCropsScreen> createState() => _EditCropsScreenState();
}

class _EditCropsScreenState extends State<EditCropsScreen> {
  Set<String> _selectedCrops = {};
  bool _isLoading = false;

  // Available crop options - predefined options only
  final List<String> _availableCrops = [
    'Rice',
    'Wheat',
    'Corn',
    'Tomatoes',
    'Potatoes',
    'Onions',
    'Carrots',
    'Cabbage',
    'Lettuce',
    'Spinach',
    'Cucumber',
    'Bell Peppers',
    'Eggplant',
    'Okra',
    'Beans',
    'Peas',
    'Chili',
    'Ginger',
    'Turmeric',
    'Coconut',
    'Banana',
    'Mango',
    'Papaya',
    'Pineapple',
    'Avocado',
    'Lemon',
    'Orange',
    'Grapes',
    'Strawberries',
    'Blueberries',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentCrops();
  }

  void _loadCurrentCrops() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user?.crops != null) {
      _selectedCrops = Set<String>.from(user!.crops!);
    }
  }

  void _toggleCrop(String crop) {
    setState(() {
      if (_selectedCrops.contains(crop)) {
        _selectedCrops.remove(crop);
      } else {
        _selectedCrops.add(crop);
      }
    });
  }

  Future<void> _saveCrops() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('🔵 EditCropsScreen - Saving crops: ${_selectedCrops.toList()}');
      
      // Update crops in the provider
      await authProvider.updateCrops(_selectedCrops.toList());
      print('🔵 EditCropsScreen - Crops update completed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crops updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update crops: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit My Crops'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single Unified Card
                Expanded(
                  child: Container(
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
                        // Header Section
                        Row(
                          children: [
                            Icon(
                              Icons.eco,
                              color: AppTheme.primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'My Crops',
                              style: AppTheme.heading3.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select the crops you cultivate on your farm',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_selectedCrops.length} selected',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Available crops section
                        Text(
                          'Available crops:',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _availableCrops.map((crop) {
                                final isSelected = _selectedCrops.contains(crop);
                                
                                return GestureDetector(
                                  onTap: () => _toggleCrop(crop),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : AppTheme.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.primaryGreen.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check : Icons.eco,
                                          size: 18,
                                          color: isSelected ? Colors.white : AppTheme.primaryGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          crop,
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: isSelected ? Colors.white : AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Save Button
                GradientButton(
                  onPressed: _isLoading ? null : _saveCrops,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Save Crops',
                              style: AppTheme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
    );
  }
}
