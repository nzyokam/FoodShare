import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:foodsharing/auth/auth_gate.dart';
import 'package:foodshare/models/restaurant_model.dart';
import 'package:foodshare/models/shelter_model.dart';
import 'package:foodshare/services/auth_service.dart';
import 'package:foodshare/models/user_model.dart';
class EditProfileScreen extends StatefulWidget {
  final UserType userType;
  final Restaurant? restaurant;
  final Shelter? shelter;

  const EditProfileScreen({
    super.key,
    required this.userType,
    this.restaurant,
    this.shelter,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

// Restaurant controllers
  TextEditingController? _businessNameController;
  TextEditingController? _businessLicenseController;
  TextEditingController? _addressController;
  TextEditingController? _cityController;
  TextEditingController? _phoneController;
  TextEditingController? _descriptionController;
  List<String> _cuisineTypes = [];

  // Shelter controllers
  TextEditingController? _organizationNameController;
  TextEditingController? _registrationNumberController;
  TextEditingController? _capacityController;
  TextEditingController? _targetDemographicController;

  // Available cuisine types for restaurants
  final List<String> _availableCuisines = [
    'Italian', 'Chinese', 'Mexican', 'Indian', 'American', 
    'French', 'Japanese', 'Thai', 'Mediterranean', 'Fast Food'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.userType == UserType.restaurant) {
      _businessNameController = TextEditingController(text: widget.restaurant?.businessName ?? '');
      _businessLicenseController = TextEditingController(text: widget.restaurant?.businessLicense ?? '');
      _addressController = TextEditingController(text: widget.restaurant?.address ?? '');
      _cityController = TextEditingController(text: widget.restaurant?.city ?? '');
      _phoneController = TextEditingController(text: widget.restaurant?.phone ?? '');
      _descriptionController = TextEditingController(text: widget.restaurant?.description ?? '');
      _cuisineTypes = List.from(widget.restaurant?.cuisineTypes ?? []);
    } else {
      _organizationNameController = TextEditingController(text: widget.shelter?.organizationName ?? '');
      _registrationNumberController = TextEditingController(text: widget.shelter?.registrationNumber ?? '');
      _addressController = TextEditingController(text: widget.shelter?.address ?? '');
      _cityController = TextEditingController(text: widget.shelter?.city ?? '');
      _phoneController = TextEditingController(text: widget.shelter?.phone ?? '');
      _descriptionController = TextEditingController(text: widget.shelter?.description ?? '');
      _capacityController = TextEditingController(text: widget.shelter?.capacity.toString() ?? '');
      _targetDemographicController = TextEditingController(text: widget.shelter?.targetDemographic ?? '');
    }
  }

@override
  void dispose() {
    // Dispose all controllers
    _businessNameController?.dispose();
    _businessLicenseController?.dispose();
    _addressController?.dispose();
    _cityController?.dispose();
    _phoneController?.dispose();
    _descriptionController?.dispose();
    _organizationNameController?.dispose();
    _registrationNumberController?.dispose();
    _capacityController?.dispose();
    _targetDemographicController?.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;

    
if (widget.userType == UserType.restaurant) {
        final updatedRestaurant = Restaurant(
          uid: user.uid,
          businessName: _businessNameController!.text.trim(),
          businessLicense: _businessLicenseController!.text.trim(),
          address: _addressController!.text.trim(),
          city: _cityController!.text.trim(),
          phone: _phoneController!.text.trim(),
          description: _descriptionController!.text.trim(),
          cuisineTypes: _cuisineTypes,
          operatingHours: widget.restaurant?.operatingHours ?? {},
          isVerified: widget.restaurant?.isVerified ?? false,
          createdAt: widget.restaurant?.createdAt ?? Timestamp.now(),
        );

        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(user.uid)
            .update(updatedRestaurant.toJson());
      } else {
        final updatedShelter = Shelter(
          uid: user.uid,
          organizationName: _organizationNameController!.text.trim(),
          registrationNumber: _registrationNumberController!.text.trim(),
          address: _addressController!.text.trim(),
          city: _cityController!.text.trim(),
          phone: _phoneController!.text.trim(),
          description: _descriptionController!.text.trim(),
          capacity: int.parse(_capacityController!.text.trim()),
          targetDemographic: _targetDemographicController!.text.trim(),
          coordinates: widget.shelter?.coordinates,
          createdAt: widget.shelter?.createdAt ?? Timestamp.now(),
        );
        await FirebaseFirestore.instance
            .collection('shelters')
            .doc(user.uid)
            .update(updatedShelter.toJson());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (widget.userType == UserType.restaurant)
                _buildRestaurantForm()
              else
                _buildShelterForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantForm() {
    return Column(
      children: [
        _buildTextFormField(
          controller: _businessNameController!,
          label: 'Business Name',
          hint: 'Enter your restaurant name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter business name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _businessLicenseController!,
          label: 'Business License',
          hint: 'Enter your business license number',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter business license';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _addressController!,
          label: 'Address',
          hint: 'Enter your restaurant address',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _cityController!,
          label: 'City',
          hint: 'Enter your city',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter city';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _phoneController!,
          label: 'Phone',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildCuisineTypeSelector(),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _descriptionController!,
          label: 'Description',
          hint: 'Describe your restaurant',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildShelterForm() {
    return Column(
      children: [
        _buildTextFormField(
          controller: _organizationNameController!,
          label: 'Organization Name',
          hint: 'Enter your organization name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter organization name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _registrationNumberController!,
          label: 'Registration Number',
          hint: 'Enter your registration number',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter registration number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _addressController!,
          label: 'Address',
          hint: 'Enter your shelter address',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _cityController!,
          label: 'City',
          hint: 'Enter your city',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter city';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _phoneController!,
          label: 'Phone',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _capacityController!,
          label: 'Capacity',
          hint: 'Enter shelter capacity (number of people)',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter capacity';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _targetDemographicController!,
          label: 'Target Demographic',
          hint: 'e.g., Families, Single adults, etc.',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter target demographic';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextFormField(
          controller: _descriptionController!,
          label: 'Description',
          hint: 'Describe your shelter and services',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildCuisineTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisine Types',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCuisines.map((cuisine) {
            final isSelected = _cuisineTypes.contains(cuisine);
            return FilterChip(
              label: Text(cuisine),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _cuisineTypes.add(cuisine);
                  } else {
                    _cuisineTypes.remove(cuisine);
                  }
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary.withAlpha(50),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
        if (_cuisineTypes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one cuisine type',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}