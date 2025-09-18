import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crop_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import 'ai_analysis_result_screen.dart';

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController();
  final _landAreaController = TextEditingController();
  
  String? _selectedYear;
  String? _selectedDistrict;
  String? _selectedSeason;
  String? _selectedSoilType;
  String? _selectedCrop;
  
  // Planning Years
  final List<String> _years = [
    '2024', '2025', '2026', '2027', '2028', '2029', '2030'
  ];
  
  // Available Districts (25 districts)
  final List<String> _districts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya'
  ];
  
  // Available Seasons
  final List<String> _seasons = [
    'Yala',
    'Maha'
  ];
  
  // Soil Types
  final List<String> _soilTypes = [
    'Alluvial Soils',
    'Calcic Red Latosols',
    'Latosols',
    'Red-Yellow Podzolic Soils',
    'Reddish Brown Earths',
    'Regosols'
  ];
  
  // Available Crops (19 specific crops as requested)
  final List<String> _crops = [
    'Banana',
    'Beans',
    'Big Onion',
    'Brinjal',
    'Cabbage',
    'Carrot',
    'Chili',
    'Coconut',
    'Maize',
    'Mango',
    'Manioc',
    'Paddy',
    'Papaya',
    'Potato',
    'Pumpkin',
    'Rubber',
    'Sweet Potato',
    'Tea',
    'Tomato'
  ];

  @override
  void dispose() {
    _temperatureController.dispose();
    _landAreaController.dispose();
    super.dispose();
  }

  void _analyzeWithAI() async {
    if (_formKey.currentState!.validate()) {
      final cropProvider = Provider.of<CropProvider>(context, listen: false);
      
      final inputData = {
        'planningYear': _selectedYear,
        'district': _selectedDistrict,
        'season': _selectedSeason,
        'temperature': _temperatureController.text.isNotEmpty 
            ? double.tryParse(_temperatureController.text) 
            : null,
        'soilType': _selectedSoilType,
        'landArea': _landAreaController.text.isNotEmpty 
            ? double.tryParse(_landAreaController.text) 
            : null,
        'crop': _selectedCrop,
      };
      
      await cropProvider.getPrediction(inputData);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AIAnalysisResultScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 24),
                
                // Form
                _buildPredictionForm(),
                
                const SizedBox(height: 24),
                
                // Analyze Button
                _buildAnalyzeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.psychology,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'AI Crop Prediction',
            style: AppTheme.heading2.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get intelligent recommendations for sustainable farming',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input Parameters',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Planning Year (Required)
            _buildDropdownField(
              label: 'Planning Year *',
              value: _selectedYear,
              items: _years,
              onChanged: (value) => setState(() => _selectedYear = value),
              icon: Icons.calendar_today,
              isRequired: true,
            ),
            
            const SizedBox(height: 16),
            
            // Available Districts (Required)
            _buildAutocompleteField(
              label: 'Available Districts *',
              value: _selectedDistrict,
              options: _districts,
              onChanged: (value) => setState(() => _selectedDistrict = value),
              icon: Icons.location_on,
              isRequired: true,
            ),
            
            const SizedBox(height: 16),
            
            // Available Seasons (Required)
            _buildDropdownField(
              label: 'Available Seasons *',
              value: _selectedSeason,
              items: _seasons,
              onChanged: (value) => setState(() => _selectedSeason = value),
              icon: Icons.wb_sunny,
              isRequired: true,
            ),
            
            const SizedBox(height: 16),
            
            // Temperature (Optional)
            TextFormField(
              controller: _temperatureController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Temperature (°C) - Optional',
                prefixIcon: Icon(Icons.thermostat),
                hintText: 'e.g., 28',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Soil Type (Optional)
            _buildAutocompleteField(
              label: 'Soil Type - Optional',
              value: _selectedSoilType,
              options: _soilTypes,
              onChanged: (value) => setState(() => _selectedSoilType = value),
              icon: Icons.landscape,
            ),
            
            const SizedBox(height: 16),
            
            // Land Area (Optional)
            TextFormField(
              controller: _landAreaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Land Area in hectare - Optional',
                prefixIcon: Icon(Icons.crop_landscape),
                hintText: 'e.g., 5.5',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Available Crops (Required)
            _buildAutocompleteField(
              label: 'Available Crops *',
              value: _selectedCrop,
              options: _crops,
              onChanged: (value) => setState(() => _selectedCrop = value),
              icon: Icons.eco,
              isRequired: true,
            ),
            
            const SizedBox(height: 24),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.mintGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fields marked with * are required. Optional fields help improve accuracy.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool isRequired = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      } : null,
    );
  }

  Widget _buildAutocompleteField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool isRequired = false,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Autocomplete<String>(
          initialValue: value != null ? TextEditingValue(text: value) : null,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return options;
            }
            return options.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            onChanged(selection);
            setState(() {}); // Force rebuild to update the field
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            // Update controller text when value changes
            if (value != null && textEditingController.text != value) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                textEditingController.text = value;
              });
            }
            
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    // Show dropdown when suffix icon is pressed
                    _showDropdownDialog(context, options, onChanged, label);
                  },
                ),
              ),
              validator: isRequired ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                if (!options.contains(value)) {
                  return 'Please select a valid option';
                }
                return null;
              } : (value) {
                if (value != null && value.isNotEmpty && !options.contains(value)) {
                  return 'Please select a valid option';
                }
                return null;
              },
              onChanged: (value) {
                onChanged(value.isEmpty ? null : value);
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            option,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDropdownDialog(
    BuildContext context,
    List<String> options,
    ValueChanged<String?> onChanged,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    onChanged(option);
                    Navigator.of(context).pop();
                    setState(() {}); // Force rebuild after selection
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyzeButton() {
    return Consumer<CropProvider>(
      builder: (context, cropProvider, child) {
        return GradientButton(
          onPressed: cropProvider.isLoading ? null : _analyzeWithAI,
          child: cropProvider.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analyzing...',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Analyze with AI',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}