import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../models/recovery_model.dart';
import '../services/firestore_service.dart';

class RecoveryVerificationScreen extends StatefulWidget {
  final ItemModel item;

  const RecoveryVerificationScreen({super.key, required this.item});

  @override
  State<RecoveryVerificationScreen> createState() => _RecoveryVerificationScreenState();
}

class _RecoveryVerificationScreenState extends State<RecoveryVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementCtrl = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _statementCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final email = currentUser?.email ?? '';
      final securityCode = Random().nextInt(99) + 1;
      
      final recovery = RecoveryModel(
        id: '',
        targetItemId: widget.item.id,
        claimantId: currentUser!.uid,
        claimantEmail: email,
        statement: _statementCtrl.text.trim(),
        finderId: widget.item.postedBy,
        securityCode: securityCode,
        timestamp: DateTime.now(),
      );

      await _firestoreService.submitRecoveryClaim(recovery);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Claim Verification Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your security code to present to the finder is:', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  '$securityCode',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                ),
                const SizedBox(height: 16),
                const Text('Please ensure you match this number with the finder when meeting face-to-face.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Got it', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted. You can now contact the finder.'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Recovery Verification', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
         backgroundColor: Colors.white,
         elevation: 0,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A2E)),
           onPressed: () => Navigator.of(context).pop(),
         ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digital Accountability Trail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 10),
              const Text(
                'To claim this item and contact the finder, you must provide a confirmation statement acknowledging digital and legal responsibility.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              const Text('Institutional Email', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: email,
                style: const TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),

              const Text('Confirmation Statement', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _statementCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'I formally declare that I am the owner of this item...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please provide a confirmation statement.';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
