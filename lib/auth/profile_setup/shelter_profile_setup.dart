import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_snackbar.dart';

class ShelterProfileSetup extends StatefulWidget {
  const ShelterProfileSetup({super.key});

  @override
  State<ShelterProfileSetup> createState() => _ShelterProfileSetupState();
}

class _ShelterProfileSetupState extends State<ShelterProfileSetup> {
  final _formKey = GlobalKey<FormState>();

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
    'Nairobi', 'Mombasa', 'Nakuru', 'Eldoret', 'Kisumu', 'Thika', 'Nyeri', 'Other',
  ];

  final List<String> _demographicOptions = [
    'Homeless individuals', 'Families in need', 'Children and orphans',
    'Elderly persons', 'Persons with disabilities', 'Refugees and asylum seekers',
    'Street children', 'Women and children', 'Mixed demographics', 'Other vulnerable groups',
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
      await ProfileService.saveShelter(
        organizationName: _organizationNameController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity,
        phone: _phoneController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 0,
        targetDemographic: _selectedDemographic,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Profile created successfully! Welcome to FoodShare!');
        }
      }
    } catch (e) {
      _showError('Error creating profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) => AppSnackBar.showError(context, message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Image.asset('lib/assets/transparent.png', fit: BoxFit.contain),
        title: Text('Organization Profile',
            style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.home, size: 60, color: Color(0xFF2E7D32)),
                    const SizedBox(height: 10),
                    Text('Tell us about your organization',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 5),
                    Text('This helps restaurants find and connect with you',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160)),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _organizationNameController,
                label: 'Organization/Shelter Name *',
                hint: 'e.g., Hope Children\'s Home',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Organization name is required' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _registrationNumberController,
                label: 'Registration Number *',
                hint: 'NGO/CBO registration number',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Registration number is required' : null,
              ),
              const SizedBox(height: 20),
              _buildDropdown('City *', 'Select your city', _cities, _selectedCity,
                  (v) => setState(() => _selectedCity = v ?? '')),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _addressController,
                label: 'Full Address *',
                hint: 'Street, building, area',
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number *',
                hint: '+254 700 000 000',
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _capacityController,
                label: 'Capacity (Number of people you serve) *',
                hint: 'e.g., 50',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Capacity is required';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                'Primary Target Demographic *',
                'Select primary demographic',
                _demographicOptions,
                _selectedDemographic,
                (v) => setState(() => _selectedDemographic = v ?? ''),
                itemFontSize: 14,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descriptionController,
                label: 'Organization Description *',
                hint: 'Describe your mission, who you serve, and your impact in the community',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Complete Setup',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String hint,
    List<String> items,
    String value,
    void Function(String?) onChanged, {
    double itemFontSize = 16,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          decoration: _inputDecoration(hint),
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(i, style: TextStyle(fontSize: itemFontSize)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1)),
      );
}
