import 'package:flutter/material.dart';
import 'package:foodshare/models/restaurant_model.dart';
import 'package:foodshare/models/shelter_model.dart';
import 'package:foodshare/models/user_model.dart';
import 'package:foodshare/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserType userType;
  final Restaurant? restaurant;
  final Shelter? shelter;

  const EditProfileScreen({super.key, required this.userType, this.restaurant, this.shelter});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
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

  final List<String> _availableCuisines = [
    'Italian', 'Chinese', 'Mexican', 'Indian', 'American',
    'French', 'Japanese', 'Thai', 'Mediterranean', 'Fast Food'
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
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
      _capacityController = TextEditingController(text: widget.shelter?.capacity?.toString() ?? '');
      _targetDemographicController = TextEditingController(text: widget.shelter?.targetDemographic ?? '');
    }
  }

  @override
  void dispose() {
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
      if (widget.userType == UserType.restaurant) {
        await ProfileService.saveRestaurant(
          businessName: _businessNameController!.text.trim(),
          businessLicense: _businessLicenseController!.text.trim(),
          address: _addressController!.text.trim(),
          city: _cityController!.text.trim(),
          phone: _phoneController!.text.trim(),
          description: _descriptionController!.text.trim(),
          cuisineTypes: _cuisineTypes,
        );
      } else {
        await ProfileService.saveShelter(
          organizationName: _organizationNameController!.text.trim(),
          registrationNumber: _registrationNumberController!.text.trim(),
          address: _addressController!.text.trim(),
          city: _cityController!.text.trim(),
          phone: _phoneController!.text.trim(),
          description: _descriptionController!.text.trim(),
          capacity: int.tryParse(_capacityController!.text.trim()),
          targetDemographic: _targetDemographicController!.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), const Text('Edit Profile')]),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _saveProfile, child: const Text('Save', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: widget.userType == UserType.restaurant ? _restaurantForm() : _shelterForm(),
        ),
      ),
    );
  }

  Widget _restaurantForm() => Column(children: [
    _field(_businessNameController!, 'Business Name', 'Your restaurant name', required: true),
    const SizedBox(height: 16),
    _field(_businessLicenseController!, 'Business License', 'Business license number', required: true),
    const SizedBox(height: 16),
    _field(_addressController!, 'Address', 'Restaurant address', required: true),
    const SizedBox(height: 16),
    _field(_cityController!, 'City', 'Your city', required: true),
    const SizedBox(height: 16),
    _field(_phoneController!, 'Phone', 'Phone number', required: true, type: TextInputType.phone),
    const SizedBox(height: 16),
    _cuisineSelector(),
    const SizedBox(height: 16),
    _field(_descriptionController!, 'Description', 'Describe your restaurant', required: true, maxLines: 4),
  ]);

  Widget _shelterForm() => Column(children: [
    _field(_organizationNameController!, 'Organization Name', 'Your organization name', required: true),
    const SizedBox(height: 16),
    _field(_registrationNumberController!, 'Registration Number', 'Registration number', required: true),
    const SizedBox(height: 16),
    _field(_addressController!, 'Address', 'Shelter address', required: true),
    const SizedBox(height: 16),
    _field(_cityController!, 'City', 'Your city', required: true),
    const SizedBox(height: 16),
    _field(_phoneController!, 'Phone', 'Phone number', required: true, type: TextInputType.phone),
    const SizedBox(height: 16),
    _field(_capacityController!, 'Capacity', 'Number of people', required: true, type: TextInputType.number,
        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : int.tryParse(v!) == null ? 'Enter a valid number' : null),
    const SizedBox(height: 16),
    _field(_targetDemographicController!, 'Target Demographic', 'e.g., Families, Single adults', required: true),
    const SizedBox(height: 16),
    _field(_descriptionController!, 'Description', 'Describe your shelter', required: true, maxLines: 4),
  ]);

  Widget _field(TextEditingController ctrl, String label, String hint, {
    bool required = false, int maxLines = 1, TextInputType? type, String? Function(String?)? validator
  }) =>
      TextFormField(
        controller: ctrl, maxLines: maxLines, keyboardType: type,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
        ),
        validator: validator ?? (required ? (v) => (v?.trim().isEmpty ?? true) ? 'Please enter $label' : null : null),
      );

  Widget _cuisineSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cuisine Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _availableCuisines.map((c) {
          final selected = _cuisineTypes.contains(c);
          return FilterChip(
            label: Text(c), selected: selected,
            onSelected: (v) => setState(() => v ? _cuisineTypes.add(c) : _cuisineTypes.remove(c)),
            selectedColor: Theme.of(context).colorScheme.primary.withAlpha(50),
            checkmarkColor: Theme.of(context).colorScheme.primary,
          );
        }).toList(),
      ),
    ],
  );
}
