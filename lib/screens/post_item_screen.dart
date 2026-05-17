import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _type = 'lost';
  String _category = 'Electronics';
  File? _imageFile;
  bool _loading = false;

  final List<String> _categories = [
    'Electronics',
    'Books & Notes',
    'ID & Cards',
    'Clothing',
    'Keys',
    'Bags',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (profile != null && profile.phoneNumber.isNotEmpty) {
        if (mounted) {
          setState(() {
            _phoneCtrl.text = profile.phoneNumber;
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _firestoreService.uploadImage(_imageFile!, user.uid);
      }
      final item = ItemModel(
        id: '',
        type: _type,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        location: _locationCtrl.text.trim(),
        imageUrl: imageUrl,
        postedBy: user.uid,
        posterName: user.displayName ?? 'SIMAD Student',
        posterPhone: _phoneCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await _firestoreService.addItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item posted successfully!'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Report Item',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type selector
            _sectionLabel('What are you reporting?'),
            const SizedBox(height: 10),
            Row(
              children: [
                _typeButton(
                  'lost',
                  'I Lost Something',
                  Icons.search_off_rounded,
                  const Color(0xFFE53935),
                ),
                const SizedBox(width: 12),
                _typeButton(
                  'found',
                  'I Found Something',
                  Icons.check_circle_outline_rounded,
                  const Color(0xFF43A047),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image picker
            _sectionLabel('Photo (Optional)'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1A73E8).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Color(0xFF1A73E8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add photo',
                            style: TextStyle(
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            _sectionLabel('Category'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: Color(0xFF1A73E8),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 4,
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            _sectionLabel('Item Title'),
            const SizedBox(height: 10),
            _buildField(
              controller: _titleCtrl,
              hint: 'e.g. Black iPhone 14, Student ID card...',
              icon: Icons.label_outline_rounded,
              validator: (v) => v!.isEmpty ? 'Enter item title' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _sectionLabel('Description'),
            const SizedBox(height: 10),
            _buildField(
              controller: _descCtrl,
              hint: 'Describe the item in detail...',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Enter a description' : null,
            ),
            const SizedBox(height: 16),

            // Location
            _sectionLabel('Location'),
            const SizedBox(height: 10),
            _buildField(
              controller: _locationCtrl,
              hint: 'e.g. Library, Cafeteria, Block A...',
              icon: Icons.location_on_outlined,
              validator: (v) => v!.isEmpty ? 'Enter location' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            _sectionLabel('WhatsApp Number'),
            const SizedBox(height: 10),
            _buildField(
              controller: _phoneCtrl,
              hint: '+252XXXXXXXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v!.isEmpty ? 'Enter your WhatsApp number' : null,
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Post Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
        fontSize: 14,
      ),
    );
  }

  Widget _typeButton(String value, String label, IconData icon, Color color) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFE0E0E0),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? color : Colors.grey,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
      ),
    );
  }
}
