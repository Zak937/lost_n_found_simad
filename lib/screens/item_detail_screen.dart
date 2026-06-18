import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item_model.dart';
import '../models/recovery_model.dart';
import '../services/firestore_service.dart';
import 'edit_item_screen.dart';
import 'recovery_verification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _hasClaimed = false;
  bool _isLoading = true;
  RecoveryModel? _recoveryLog;

  @override
  void initState() {
    super.initState();
    _checkRecoveryState();
  }

  Future<void> _checkRecoveryState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.uid == widget.item.postedBy) {
        if (widget.item.itemStatus == 'Recovered') {
          try {
            final rec = await FirestoreService().getRecoveryByItemId(widget.item.id);
            if (mounted) {
              setState(() {
                _recoveryLog = rec;
                _isLoading = false;
              });
            }
          } catch (e) {
            debugPrint('Error getting recovery log: $e');
            if (mounted) setState(() => _isLoading = false);
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        try {
          final rec = await FirestoreService().getRecoveryByItemAndClaimant(widget.item.id, user.uid);
          if (mounted) {
            setState(() {
              _hasClaimed = rec != null;
              _isLoading = false;
            });
          }
        } catch (e) {
          debugPrint('Error getting claimant recovery log: $e');
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _typeColor =>
      widget.item.type == 'lost' ? const Color(0xFFE53935) : const Color(0xFF43A047);

  String get _typeLabel => widget.item.type == 'lost' ? 'LOST' : 'FOUND';

  Future<void> _openWhatsApp(BuildContext context) async {
    final cleaned = widget.item.posterPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final message = Uri.encodeComponent(
      'Hi! I have verified my claim for your "${widget.item.title}" post on the SIMAD app. Please provide me with the hidden verification questions.',
    );
    final uri = Uri.parse('https://wa.me/$cleaned?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _updateStatusDialog(
    BuildContext context,
    String title,
    String msg,
    String newStatus,
    bool resolve,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await FirestoreService().updateItemStatus(
        widget.item.id,
        newStatus,
        resolve: resolve,
      );
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _reportFraudDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Report Fraudulent Claim', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to report this claim as fraudulent? This will reset the item status to Lost/Found and alert the administration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Report Fraud', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted && _recoveryLog != null) {
      await FirestoreService().reportFakeClaim(_recoveryLog!.id, widget.item.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim reported as fraudulent.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.item.postedBy;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: widget.item.imageUrl.isNotEmpty ? 280 : 120,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Color(0xFF1A1A2E),
                    size: 18,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              if (isOwner && !widget.item.isResolved)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF1A73E8), size: 18),
                      onPressed: () async {
                        final updated = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => EditItemScreen(item: widget.item))
                        );
                        if (updated == true && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.item.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _typeLabel,
                          style: TextStyle(
                            color: _typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.category,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(widget.item.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Info cards
                  _infoCard(
                    Icons.description_outlined,
                    'Description',
                    widget.item.description,
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    Icons.location_on_outlined,
                    'Location',
                    widget.item.location,
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    Icons.person_outline_rounded,
                    'Posted By',
                    widget.item.posterName,
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (!isOwner && !widget.item.isResolved) ...[
                    if (_hasClaimed) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text(
                            'Contact via WhatsApp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else if (widget.item.itemStatus != 'Recovered') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RecoveryVerificationScreen(item: widget.item)),
                            );
                            if (result == true) {
                              _checkRecoveryState();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.assignment_turned_in_rounded),
                          label: const Text(
                            'Claim Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_rounded, color: Colors.grey),
                          label: const Text('Already Claimed', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
                  ],

                  if (isOwner && !widget.item.isResolved) ...[
                    if (widget.item.itemStatus == 'Recovered' && _recoveryLog != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _reportFraudDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.report_problem_rounded),
                          label: const Text(
                            'Report Fraud / Fake Claim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatusDialog(
                            context,
                            'Confirm Handover',
                            'Have you verified the claimant and handed over the item? This will close the post permanently.',
                            'Recovered',
                            true,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF43A047),
                            side: const BorderSide(color: Color(0xFF43A047)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'Confirm Valid Handover',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatusDialog(
                            context,
                            'Mark as Recovered',
                            'Are you sure you want to mark this item as recovered? It will be removed from the main feed.',
                            'Recovered',
                            true,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'Mark as Recovered',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text(
                                'Delete this item permanently?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await FirestoreService().deleteItem(widget.item.id);
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE53935)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFE53935),
                        ),
                        label: const Text(
                          'Delete Post',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
          // Real-time StreamBuilder for displaying Claims & Security Codes
          SliverToBoxAdapter(
            child: StreamBuilder<List<RecoveryModel>>(
              stream: FirestoreService().getVerificationsStream(widget.item.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                final claims = snapshot.data!;
                
                if (isOwner) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Claim Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 12),
                        ...claims.map((c) => _buildClaimCard(c)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                } else {
                  final myClaim = claims.where((c) => c.claimantId == currentUser?.uid).firstOrNull;
                  if (myClaim != null && myClaim.securityCode != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1A73E8), width: 2)),
                        child: Column(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF1A73E8), size: 32),
                            const SizedBox(height: 12),
                            const Text('Your Security Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A73E8))),
                            const SizedBox(height: 8),
                            Text('${myClaim.securityCode}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), letterSpacing: 4)),
                            const SizedBox(height: 8),
                            const Text('Present this exact number to the finder to verify your identity when retrieving the item.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(RecoveryModel claim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(claim.claimantEmail, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Text('"${claim.statement}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security_rounded, size: 18, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text('Security Code: ${claim.securityCode ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE8F0FE),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 60, color: Color(0xFF1A73E8)),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
