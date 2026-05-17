import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _loading = true;
  bool _saving = false;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (profile != null) {
        _userModel = profile;
        _nameCtrl.text = profile.displayName;
        _phoneCtrl.text = profile.phoneNumber;
      } else {
        // If profile doesn't exist, create a default one
        _userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'SIMAD Student',
          phoneNumber: '',
        );
        _nameCtrl.text = _userModel!.displayName;
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _userModel != null) {
      final updatedUser = UserModel(
        id: user.uid,
        email: _userModel!.email,
        displayName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
      );
      
      // Update Firebase Auth display name as well
      await user.updateDisplayName(updatedUser.displayName);
      
      // Update Firestore
      await _firestoreService.updateUserProfile(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF43A047)),
        );
        Navigator.pop(context, true);
      }
    }
    
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildField(
                  controller: _nameCtrl,
                  label: 'Display Name',
                  hint: 'Enter your name',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Default WhatsApp Number',
                  hint: '+252XXXXXXXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Phone number cannot be empty' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2)),
          ),
        ),
      ],
    );
  }
}
