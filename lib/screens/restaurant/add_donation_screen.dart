import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../services/profile_service.dart';

const _kGreen    = Color(0xFF38563B);
const _kGreenMid = Color(0xFF506F52);

class AddDonationScreen extends StatefulWidget {
  final Donation? donation;
  const AddDonationScreen({super.key, this.donation});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _quantityCtrl = TextEditingController();

  late final TapGestureRecognizer _guidelinesRecognizer;

  DonationCategory _selectedCategory = DonationCategory.other;
  String _selectedUnit = 'kg';
  DateTime? _expiryDate;
  DateTime? _pickupTime;
  bool _isLoading = false;

  XFile?      _pickedFile;
  Uint8List?  _imageBytes;
  bool        _uploadingImage = false;
  List<String> _existingImageUrls = [];

  static const _units = ['kg', 'g', 'portions', 'boxes', 'litres', 'pieces', 'bags'];

  @override
  void initState() {
    super.initState();
    _guidelinesRecognizer = TapGestureRecognizer()
      ..onTap = () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Community Guidelines coming soon!', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
    if (widget.donation != null) _loadExisting();
  }

  void _loadExisting() {
    final d = widget.donation!;
    _titleCtrl.text    = d.title;
    _descCtrl.text     = d.description ?? '';
    _quantityCtrl.text = d.quantity?.toString() ?? '';
    _selectedUnit      = d.unit ?? 'kg';
    _selectedCategory  = d.category ?? DonationCategory.other;
    _expiryDate        = d.expiryDate;
    _pickupTime        = d.pickupTime;
    _existingImageUrls = List<String>.from(d.imageUrls);
  }

  @override
  void dispose() {
    _guidelinesRecognizer.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, maxHeight: 1200, imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() { _pickedFile = picked; _imageBytes = bytes; });
  }

  Future<List<String>> _uploadImageIfNeeded() async {
    if (_imageBytes == null || _pickedFile == null) return _existingImageUrls;
    setState(() => _uploadingImage = true);
    try {
      final url = await DonationService.uploadImage(_imageBytes!, _pickedFile!.name);
      return [url];
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickDateTime(bool isExpiry) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => isExpiry ? _expiryDate = dt : _pickupTime = dt);
  }

  String _categoryToApi(DonationCategory cat) =>
      cat == DonationCategory.preparedMeals ? 'prepared_meals' : cat.name;

  Future<void> _saveDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null || _pickupTime == null) {
      _showError('Please set both expiry date and pickup time');
      return;
    }
    if (_imageBytes == null && _existingImageUrls.isEmpty) {
      _showError('Please add a photo of the donation');
      return;
    }
    setState(() => _isLoading = true);
    try {
      String? city;
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        final restaurant = await ProfileService.getRestaurant(userId);
        city = restaurant?.city;
      }
      final imageUrls = await _uploadImageIfNeeded();

      if (widget.donation != null) {
        await DonationService.updateDonation(
          widget.donation!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _categoryToApi(_selectedCategory),
          quantity: int.tryParse(_quantityCtrl.text),
          unit: _selectedUnit,
          expiryDate: _expiryDate,
          pickupTime: _pickupTime,
          imageUrls: imageUrls,
          city: city,
        );
        if (mounted) _showSuccess('Donation updated!');
      } else {
        await DonationService.createDonation(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _categoryToApi(_selectedCategory),
          quantity: int.tryParse(_quantityCtrl.text),
          unit: _selectedUnit,
          expiryDate: _expiryDate,
          pickupTime: _pickupTime,
          imageUrls: imageUrls,
          city: city,
        );
        if (mounted) _showSuccess('Donation added!');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.plusJakartaSans()),
    backgroundColor: const Color(0xFFBA1A1A),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.plusJakartaSans()),
    backgroundColor: _kGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final isEdit = widget.donation != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
        ),
        title: Row(children: [Image.asset('lib/assets/transparent.png', width: 32, height: 32), const SizedBox(width: 10), Text(isEdit ? 'Edit Donation' : 'Add New Donation', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface))]),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo upload ──────────────────────────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageBytes != null ? cs.primary : cs.outlineVariant,
                      width: _imageBytes != null ? 2 : 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_imageBytes!, fit: BoxFit.cover),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() { _pickedFile = null; _imageBytes = null; }),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                child: Text('Tap to change', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                              ),
                            ),
                            if (_uploadingImage)
                              const ColoredBox(
                                color: Color(0x88000000),
                                child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              ),
                          ],
                        )
                      : (_existingImageUrls.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  _existingImageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined, size: 40, color: cs.outlineVariant),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _existingImageUrls = []),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                    child: Text('Tap to change', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 32, color: cs.outlineVariant),
                                const SizedBox(height: 10),
                                Text('Tap to add photo', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text('Required — JPEG or PNG', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFBA1A1A))),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 20),

              // ── Card 1: Food details ──────────────────────────────────────
              _Card(
                children: [
                  const _FieldLabel('Donation Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Title is required' : null,
                    decoration: _inputDeco('e.g. Surplus Fresh Apples', cs),
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel('Category'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DonationCategory>(
                    initialValue: _selectedCategory,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface),
                    decoration: _inputDeco('', cs),
                    dropdownColor: cs.surfaceContainer,
                    items: DonationCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(_categoryName(c), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface))))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Quantity'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _quantityCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface),
                              decoration: _inputDeco('0', cs),
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) return 'Required';
                                if (int.tryParse(v!) == null || int.parse(v) <= 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Unit'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface),
                              decoration: _inputDeco('', cs),
                              dropdownColor: cs.surfaceContainer,
                              items: _units
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface))))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedUnit = v ?? 'kg'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurface),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Description is required' : null,
                    decoration: _inputDeco('Add details about the condition, variety, etc.', cs),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Card 2: Time & location ───────────────────────────────────
              _Card(
                children: [
                  const _FieldLabel('Expiry Date & Time'),
                  const SizedBox(height: 8),
                  _DateField(
                    placeholder: 'Select Expiry',
                    value: _expiryDate,
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDateTime(true),
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel('Preferred Pickup Time'),
                  const SizedBox(height: 8),
                  _DateField(
                    placeholder: 'Select Time Window',
                    value: _pickupTime,
                    icon: Icons.access_time_rounded,
                    onTap: () => _pickDateTime(false),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // ── Save button ─────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreenMid,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  disabledBackgroundColor: cs.surfaceContainerHighest,
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'Update Donation' : 'Save Donation',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: 'By saving, you agree to our ',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.onSurfaceVariant),
                children: [
                  TextSpan(
                    text: 'Community Guidelines',
                    recognizer: _guidelinesRecognizer,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: cs.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: cs.primary,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, ColorScheme cs) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: cs.onSurfaceVariant),
    filled: true,
    fillColor: cs.surfaceContainer,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant, width: 0.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant, width: 0.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kGreen, width: 2)),
    errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBA1A1A))),
  );

  String _categoryName(DonationCategory c) {
    switch (c) {
      case DonationCategory.fruits:        return 'Fruits';
      case DonationCategory.vegetables:    return 'Vegetables';
      case DonationCategory.grains:        return 'Grains & Cereals';
      case DonationCategory.dairy:         return 'Dairy Products';
      case DonationCategory.meat:          return 'Meat & Fish';
      case DonationCategory.preparedMeals: return 'Prepared Meals';
      case DonationCategory.snacks:        return 'Snacks';
      case DonationCategory.beverages:     return 'Beverages';
      case DonationCategory.other:         return 'Other';
    }
  }
}

// ── Reusable form widgets ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface));
  }
}

class _DateField extends StatelessWidget {
  final String    placeholder;
  final DateTime? value;
  final IconData  icon;
  final VoidCallback onTap;
  const _DateField({required this.placeholder, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue
                    ? '${value!.day}/${value!.month}/${value!.year}  ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
                    : placeholder,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: hasValue ? cs.onSurface : cs.onSurfaceVariant),
              ),
            ),
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
