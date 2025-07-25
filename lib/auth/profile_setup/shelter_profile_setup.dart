// auth/profile_setup/shelter_profile_setup.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/shelter_model.dart';

class ShelterProfileSetup extends StatefulWidget {
  const ShelterProfileSetup({super.key});

  @override
  State<ShelterProfileSetup> createState() => _ShelterProfileSetupState();
}

class _ShelterProfileSetupState extends State<ShelterProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  // Form controllers
  final _organizationNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCity = '';
  String _selectedDemographic = '';
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

  final List<String> _demographicOptions = [
    'Homeless individuals',
    'Families in need',
    'Children and orphans',
    'Elderly persons',
    'Persons with disabilities',
    'Refugees and asylum seekers',
    'Street children',
    'Women and children',
    'Mixed demographics',
    'Other vulnerable groups'
  ];

  @override
  void dispose() {
    _organizationNameController.dispose();
    _registrationNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity.isEmpty) {
      _showError('Please select a city');
      return;
    }
    if (_selectedDemographic.isEmpty) {
      _showError('Please select target demographic');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;
      
      // Create shelter profile
      final shelter = Shelter(
        uid: user.uid,
        organizationName: _organizationNameController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity,
        phone: _phoneController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 0,
        targetDemographic: _selectedDemographic,
        description: _descriptionController.text.trim(),
        createdAt: Timestamp.now(),
      );

      // Use a batch write to ensure both operations succeed
      final batch = FirebaseFirestore.instance.batch();

      // Save shelter profile
      final shelterRef = FirebaseFirestore.instance
          .collection('shelters')
          .doc(user.uid);
      batch.set(shelterRef, shelter.toJson());

      // Mark profile as complete in users collection
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      batch.update(userRef, {
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit both operations
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully! Welcome to FoodShare! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Force a small delay to ensure Firestore updates propagate
        await Future.delayed(const Duration(milliseconds: 500));
        
       
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
          'Organization Profile',
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
                      Icons.home,
                      size: 60,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tell us about your organization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'This helps restaurants find and connect with you',
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
              
              // Organization Name
              _buildTextField(
                controller: _organizationNameController,
                label: 'Organization/Shelter Name *',
                hint: 'e.g., Hope Children\'s Home',
                 color: const Color.fromARGB(255, 188, 187, 187),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Organization name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Registration Number
              _buildTextField(
                controller: _registrationNumberController,
                label: 'Registration Number *',
                hint: 'NGO/CBO registration number',
                 color: const Color.fromARGB(255, 188, 187, 187),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Registration number is required';
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
                 color: const Color.fromARGB(255, 188, 187, 187),
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
                 color: const Color.fromARGB(255, 188, 187, 187),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Capacity
              _buildTextField(
                controller: _capacityController,
                label: 'Capacity (Number of people you serve) *',
                hint: 'e.g., 50',
                 color: const Color.fromARGB(255, 188, 187, 187),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Capacity is required';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Target Demographic
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Target Demographic *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDemographic.isEmpty ? null : _selectedDemographic,
                    decoration: InputDecoration(
                      hintText: 'Select primary demographic',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _demographicOptions.map((demographic) => DropdownMenuItem(
                      value: demographic,
                      child: Text(demographic, style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedDemographic = value ?? ''),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Organization Description *',
                hint: 'Describe your mission, who you serve, and your impact in the community',
                 color: const Color.fromARGB(255, 188, 187, 187),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
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
    String? Function(String?)? validator, required Color color,
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