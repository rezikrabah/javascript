import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class ClientReviewScreen extends StatefulWidget {
  final String commandeId;
  final String chauffeurNom;
  final double volumeLivre;
  final double prixFinal;

  const ClientReviewScreen({
    Key? key,
    required this.commandeId,
    required this.chauffeurNom,
    required this.volumeLivre,
    required this.prixFinal,
  }) : super(key: key);

  @override
  State<ClientReviewScreen> createState() => _ClientReviewScreenState();
}

class _ClientReviewScreenState extends State<ClientReviewScreen>
    with TickerProviderStateMixin {
  int _starRating = 0;
  int _hoveredStar = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentController = TextEditingController();
  bool _submitted = false;
  bool _submitting = false;

  late AnimationController _successController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  final List<Map<String, dynamic>> _tags = [
    {'label': 'Ponctuel',       'icon': Icons.access_time_filled},
    {'label': 'Propre',         'icon': Icons.cleaning_services},
    {'label': 'Courtois',       'icon': Icons.sentiment_very_satisfied},
    {'label': 'Quantité exacte','icon': Icons.water_drop},
    {'label': 'Rapide',         'icon': Icons.speed},
    {'label': 'Professionnel',  'icon': Icons.verified},
  ];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim  = CurvedAnimation(parent: _fadeController,  curve: Curves.easeOut);
    _scaleAnim = CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _successController.dispose();
    _fadeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_starRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Veuillez donner une note'),
        backgroundColor: const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    final result = await ApiService.submitClientReview(
      commandeId:  widget.commandeId,
      note:        _starRating,
      tags:        _selectedTags.toList(),
      commentaire: _commentController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['error']),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _submitted = true);
    _successController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      body: SafeArea(
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  // ── SUCCESS ───────────────────────────────────────────────
  Widget _buildSuccess() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 48),
              ),
              const SizedBox(height: 28),
              const Text('Merci pour votre avis !',
                style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w600,
                  color: Colors.white, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text('Votre retour aide à améliorer le service.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.45), height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Retour à l\'accueil',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FORM ──────────────────────────────────────────────────
  Widget _buildForm() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                Icon(Icons.water_drop, color: Colors.blue.shade400, size: 22),
              ],
            ),
            const SizedBox(height: 28),

            // Title
            const Text('Votre livraison\nest terminée',
              style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w600,
                color: Colors.white, letterSpacing: -0.8, height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text('Donnez un avis sur votre expérience',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 24),

            // Delivery summary card
            _buildDeliverySummary(),
            const SizedBox(height: 24),

            // Stars
            _buildStarSection(),
            const SizedBox(height: 20),

            // Tags
            if (_starRating > 0) ...[
              _buildTagsSection(),
              const SizedBox(height: 20),
            ],

            // Comment
            _buildCommentField(),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: Colors.white.withOpacity(0.06),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Envoyer mon avis',
                    style: TextStyle(
                        color: _starRating > 0 ? Colors.white : Colors.white38,
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1630),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF60A5FA), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chauffeurNom,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text('${widget.volumeLivre.toStringAsFixed(0)} L  ·  ${widget.prixFinal.toStringAsFixed(0)} DA',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
            ),
            child: const Text('Livré', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildStarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1630),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Text('Comment s\'est passée la livraison ?',
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              final filled = idx <= (_hoveredStar > 0 ? _hoveredStar : _starRating);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() { _starRating = idx; _hoveredStar = 0; });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: filled ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.2),
                      size: 40,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _starRating == 0 ? 'Touchez une étoile'
                  : _starRating == 1 ? 'Très décevant'
                  : _starRating == 2 ? 'Décevant'
                  : _starRating == 3 ? 'Correct'
                  : _starRating == 4 ? 'Très bien'
                  : 'Excellent !',
              key: ValueKey(_starRating),
              style: TextStyle(
                color: _starRating == 0
                    ? Colors.white.withOpacity(0.25)
                    : _starRating >= 4
                    ? const Color(0xFFF59E0B)
                    : Colors.white.withOpacity(0.55),
                fontSize: 14, fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ce qui vous a plu',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) {
            final sel = _selectedTags.contains(tag['label']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (sel) _selectedTags.remove(tag['label']);
                  else _selectedTags.add(tag['label'] as String);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF1E3A8A) : const Color(0xFF0D1630),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: sel ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tag['icon'] as IconData,
                        size: 14,
                        color: sel ? const Color(0xFF93C5FD) : Colors.white.withOpacity(0.35)),
                    const SizedBox(width: 6),
                    Text(tag['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: sel ? Colors.white : Colors.white.withOpacity(0.45),
                          fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commentaire (optionnel)',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1630),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Partagez votre expérience...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}