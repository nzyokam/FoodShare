import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum FoodCategory {
  fruits,
  vegetables,
  grains,
  dairy,
  meat,
  snacks,
  drinks,
  other,
}

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _availableDate = ValueNotifier<DateTime?>(null);

  FoodCategory? _selectedCategory;
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  // Pick date and time
  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0),
      );

      if (time != null) {
        _availableDate.value = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImages.add(File(image.path)));
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImages.add(File(image.path)));
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  // Upload a single image to Firebase Storage
  Future<String> uploadImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser!;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance
        .ref()
        .child('food_images/${user.uid}/$fileName');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Submit form and upload to Firestore
  Future<void> submitFood() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _availableDate.value == null ||
        _selectedCategory == null ||
        _selectedImages.isEmpty) {
      _showError("Please fill all fields and add at least one image");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = <String>[];
      for (File img in _selectedImages) {
        final url = await uploadImage(img);
        imageUrls.add(url);
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final city = userDoc.data()?['city'] ?? '';

      await FirebaseFirestore.instance.collection('food').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory.toString().split('.').last,
        'availableAt': _availableDate.value,
        'userId': user.uid,
        'imageUrls': imageUrls,
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Food donation added!")),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate Food')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Food Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            DropdownButtonFormField<FoodCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Select Category'),
              items: FoodCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),

            const SizedBox(height: 16),

            ValueListenableBuilder(
              valueListenable: _availableDate,
              builder: (context, value, _) {
                return Row(
                  children: [
                    Text(
                      value == null
                          ? 'Pick Available Date'
                          : 'Available: ${value.toString().substring(0, 16)}',
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: pickDateTime,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            _selectedImages.isEmpty
                ? TextButton.icon(
                    onPressed: _showImagePickerOptions,
                    icon: const Icon(Icons.image),
                    label: const Text('Add Images'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_selectedImages.length, (index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.file(_selectedImages[index], height: 100, width: 100, fit: BoxFit.cover),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _removeImage(index),
                              ),
                            ],
                          );
                        }),
                      ),
                      TextButton.icon(
                        onPressed: _showImagePickerOptions,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add More Images'),
                      )
                    ],
                  ),

            const SizedBox(height: 24),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit Donation'),
                  ),
          ],
        ),
      ),
    );
  }
}
