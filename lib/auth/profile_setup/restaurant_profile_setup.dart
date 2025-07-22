// auth/profile_setup/restaurant_profile_setup.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/restaurant_model.dart';

class RestaurantProfileSetup extends StatefulWidget {
  const RestaurantProfileSetup({super.key});

  @override
  State<RestaurantProfileSetup> createState() => _RestaurantProfileSetupState();
}

class _RestaurantProfileSetupState extends State<RestaurantProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCity = '';
  final List<String> _selectedCuisineTypes = [];
  final Map<String, String> _operatingHours = {};
  bool _isLoading = false;

  final List<String> _cities = [
    'Nairobi',
    'Mombasa',
    'Nakuru',
    'Eldoret',
    'Kisumu',
    'Thika',
    'Nyeri',
    'Other'
  ];

  final List<String> _cuisineOptions = [
    'Kenyan',
    'Italian',
    'Indian',
    'Chinese',
    'Fast Food',
    'Continental',
    'Mediterranean',
    'Mexican',
    'Japanese',
    'Vegetarian',
    'Vegan',
    'Halal',
    'Other'
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessLicenseController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity.isEmpty) {
      _showError('Please select a city');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;
      
      final restaurant = Restaurant(
        uid: user.uid,
        businessName: _businessNameController.text.trim(),
        businessLicense: _businessLicenseController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity,
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        cuisineTypes: _selectedCuisineTypes,
        operatingHours: _operatingHours,
        createdAt: Timestamp.now(),
      );

      // Save restaurant profile
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .set(restaurant.toJson());

      // Mark profile as complete
      await _authService.markProfileComplete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
        // Navigation will be handled by auth state listener
      }
    } catch (e) {
      _showError('Error creating profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Restaurant Profile',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 60,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tell us about your business',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'This helps shelters find and trust you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Business Name
              _buildTextField(
                controller: _businessNameController,
                label: 'Business/Restaurant Name *',
                hint: 'e.g., Mama\'s Kitchen',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Business License
              _buildTextField(
                controller: _businessLicenseController,
                label: 'Business License Number *',
                hint: 'Enter your business registration number',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business license is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // City Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'City *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCity.isEmpty ? null : _selectedCity,
                    decoration: InputDecoration(
                      hintText: 'Select your city',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _cities.map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCity = value ?? ''),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Address
              _buildTextField(
                controller: _addressController,
                label: 'Full Address *',
                hint: 'Street, building, area',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number *',
                hint: '+254 700 000 000',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Cuisine Types
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuisine Types (Select all that apply)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cuisineOptions.map((cuisine) {
                      final isSelected = _selectedCuisineTypes.contains(cuisine);
                      return FilterChip(
                        label: Text(cuisine),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCuisineTypes.add(cuisine);
                            } else {
                              _selectedCuisineTypes.remove(cuisine);
                            }
                          });
                        },
                        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                        selectedColor: const Color(0xFF2E7D32).withAlpha(100),
                      );
                    }).toList(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Business Description',
                hint: 'Tell shelters about your restaurant and commitment to reducing food waste',
                maxLines: 3,
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Setup',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}