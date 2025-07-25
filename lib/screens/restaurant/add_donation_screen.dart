// screens/restaurant/add_donation_screen.dart
//import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';
import '../../models/donation_model.dart';

class AddDonationScreen extends StatefulWidget {
  final Donation? donation; // For editing existing donations

  const AddDonationScreen({super.key, this.donation});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  DonationCategory _selectedCategory = DonationCategory.other;
  DateTime? _expiryDate;
  DateTime? _pickupTime;
  // final List<File> _selectedImages = [];
  // final List<String> _existingImageUrls = [];
  // final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.donation != null) {
      _loadExistingDonation();
    }
  }

  void _loadExistingDonation() {
    final donation = widget.donation!;
    _titleController.text = donation.title;
    _descriptionController.text = donation.description;
    _quantityController.text = donation.quantity.toString();
    _unitController.text = donation.unit;
    _selectedCategory = donation.category;
    _expiryDate = donation.expiryDate.toDate();
    _pickupTime = donation.pickupTime.toDate();
    //_existingImageUrls.addAll(donation.imageUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isExpiry) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isExpiry) {
            _expiryDate = dateTime;
          } else {
            _pickupTime = dateTime;
          }
        });
      }
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  // Replace your _saveDonation method to work without images:
  
  Future<void> _saveDonation() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_expiryDate == null || _pickupTime == null) {
      _showError('Please set both expiry date and pickup time');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Get restaurant city
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();
      final city = restaurantDoc.data()?['city'] ?? '';

      // For now, we'll save donations without images
      // You can add placeholder image URLs or leave empty
      final donationData = {
        'donorId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory.toString().split('.').last,
        'quantity': int.parse(_quantityController.text),
        'unit': _unitController.text.trim(),
        'expiryDate': Timestamp.fromDate(_expiryDate!),
        'pickupTime': Timestamp.fromDate(_pickupTime!),
        'imageUrls': [], // Empty array for now
        'status': 'available',
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.donation != null) {
        // Update existing donation
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(widget.donation!.id)
            .update(donationData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation updated successfully! (Images will be available after upgrading Firebase plan)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new donation
        await FirebaseFirestore.instance
            .collection('donations')
            .add(donationData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation added successfully! (Images will be available after upgrading Firebase plan)'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      _showError('Error saving donation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.donation != null ? 'Edit Donation' : 'Add Donation',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDonation,
            child: Text(
              widget.donation != null ? 'Update' : 'Save',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildTextField(
                controller: _titleController,
                label: 'Food Item Title *',
                hint: 'e.g., Fresh Vegetables, Prepared Meals',
                 color: const Color.fromARGB(255, 188, 187, 187),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Category
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DonationCategory>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: DonationCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(_getCategoryName(category)),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Quantity and Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _quantityController,
                      label: 'Quantity *',
                      hint: '10',
                       color: const Color.fromARGB(255, 141, 141, 141),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Quantity is required';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Invalid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _unitController,
                      label: 'Unit *',
                      hint: 'kg, portions, boxes',
                       color: const Color.fromARGB(255, 188, 187, 187),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unit is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description *',
                hint: 'Describe the food items, freshness, any special instructions...',
                 color: const Color.fromARGB(255, 188, 187, 187),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Date and Time Selection
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeCard(
                      'Expiry Date & Time *',
                      _expiryDate,
                      () => _pickDateTime(true),
                      Icons.schedule,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTimeCard(
                      'Pickup Time *',
                      _pickupTime,
                      () => _pickDateTime(false),
                      Icons.access_time,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
         
              
              // Save Button
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      widget.donation != null ? 'Update Donation' : 'Add Donation',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildDateTimeCard(
    String title,
    DateTime? dateTime,
    VoidCallback onTap,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateTime != null
                  ? '${dateTime.day}/${dateTime.month}/${dateTime.year}\n${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                  : 'Tap to select',
              style: TextStyle(
                fontSize: 12,
                color: dateTime != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(DonationCategory category) {
    switch (category) {
      case DonationCategory.fruits:
        return 'Fruits';
      case DonationCategory.vegetables:
        return 'Vegetables';
      case DonationCategory.grains:
        return 'Grains & Cereals';
      case DonationCategory.dairy:
        return 'Dairy Products';
      case DonationCategory.meat:
        return 'Meat & Fish';
      case DonationCategory.preparedMeals:
        return 'Prepared Meals';
      case DonationCategory.snacks:
        return 'Snacks';
      case DonationCategory.beverages:
        return 'Beverages';
      case DonationCategory.other:
        return 'Other';
    }
  }
}