import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test2/fournisseur/provider_home_screen_FINAL.dart';

import '../services/api_service.dart';

class ChauffeurReviewScreen extends StatefulWidget {
  final String commandeId;
  final String clientNom;
  final double volumeLivre;
  final String adresse;

  const ChauffeurReviewScreen({
    Key? key,
    required this.commandeId,
    required this.clientNom,
    required this.volumeLivre,
    required this.adresse,  required String driverPhone,
  }) : super(key: key);

  @override
  State<ChauffeurReviewScreen> createState() => _ChauffeurReviewScreenState();
}

class _ChauffeurReviewScreenState extends State<ChauffeurReviewScreen>
    with TickerProviderStateMixin {
  int _clientRating = 0;
  final Set<String> _selectedIssues = {};
  final Set<String> _selectedPositives = {};
  bool _accessFacile = true;
  bool _clientPresent = true;
  bool _submitted = false;
  bool _submitting = false;

  late AnimationController _successCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  late Animation<double> _successScale;

  final List<Map<String, dynamic>> _issues = [
    {'label': 'Absent à la livraison', 'icon': Icons.person_off_rounded},
    {'label': 'Adresse incorrecte',    'icon': Icons.location_off_rounded},
    {'label': 'Accès difficile',       'icon': Icons.block_rounded},
    {'label': 'Impoli',                'icon': Icons.sentiment_very_dissatisfied_rounded},
  ];

  final List<Map<String, dynamic>> _positives = [
    {'label': 'Accueil chaleureux', 'icon': Icons.favorite_rounded},
    {'label': 'Adresse précise',    'icon': Icons.location_on_rounded},
    {'label': 'Paiement rapide',    'icon': Icons.payments_rounded},
    {'label': 'Très coopératif',    'icon': Icons.handshake_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _entryCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryAnim   = CurvedAnimation(parent: _entryCtrl,   curve: Curves.easeOutCubic);
    _successScale= CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }




  Future<void> _submit() async {
    if (_clientRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Veuillez évaluer le client'),
        backgroundColor: const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    if (widget.commandeId.startsWith('gen_')) { 
      setState(() => _submitted = true);
      _successCtrl.forward();
      return;
    }

    final result = await ApiService.submitChauffeurReview(
      commandeId:    widget.commandeId,
      note:          _clientRating,
      issues:        _selectedIssues.toList(),
      positives:     _selectedPositives.toList(),
      accessFacile:  _accessFacile,
      clientPresent: _clientPresent,
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
    _successCtrl.forward();
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
      scale: _successScale,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFF59E0B), size: 50),
              ),
              const SizedBox(height: 28),
              const Text('Mission accomplie !',
                style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w600,
                  color: Colors.white, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text('Votre retour est enregistré.\nBonne route !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.4), height: 1.5)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Retour au map',
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
      opacity: _entryAnim,
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
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Livraison terminée',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Title
            const Text('Rapport de\nlivraison',
              style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w600,
                color: Colors.white, letterSpacing: -0.8, height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text('Évaluez votre expérience avec ce client',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 24),

            // Mission card
            _buildMissionCard(),
            const SizedBox(height: 20),

            // Delivery conditions
            _buildConditionsSection(),
            const SizedBox(height: 20),

            // Client rating
            _buildClientRating(),
            const SizedBox(height: 20),

            // Tags based on rating
            if (_clientRating > 0 && _clientRating >= 4) ...[
              _buildTagGrid('Points positifs', _positives, _selectedPositives,
                  const Color(0xFF10B981), const Color(0xFF10B981)),
              const SizedBox(height: 20),
            ],
            if (_clientRating > 0 && _clientRating <= 2) ...[
              _buildTagGrid('Problèmes rencontrés', _issues, _selectedIssues,
                  const Color(0xFFEF4444), const Color(0xFFEF4444)),
              const SizedBox(height: 20),
            ],

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  disabledBackgroundColor: Colors.white.withOpacity(0.05),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Soumettre le rapport',
                    style: TextStyle(
                        color: _clientRating > 0 ? Colors.white : Colors.white38,
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
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
            child: Center(
              child: Text(
                widget.clientNom.isNotEmpty
                    ? widget.clientNom.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                    : 'CL',
                style: const TextStyle(
                    color: Color(0xFF60A5FA), fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.clientNom,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(widget.adresse,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${widget.volumeLivre.toStringAsFixed(0)} L',
                  style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 15, fontWeight: FontWeight.w600)),
              Text('livrés', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1630),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conditions de livraison',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          _buildToggleRow('Accès facile au point de livraison', _accessFacile,
              Icons.directions_rounded, (v) => setState(() => _accessFacile = v)),
          const SizedBox(height: 1),
          _buildDivider(),
          const SizedBox(height: 1),
          _buildToggleRow('Client présent à l\'arrivée', _clientPresent,
              Icons.person_rounded, (v) => setState(() => _clientPresent = v)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.06), height: 1);

  Widget _buildToggleRow(String label, bool value, IconData icon, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: (value ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16,
                color: value ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400))),
          Switch(
            value: value,
            onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); },
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withOpacity(0.25),
            inactiveThumbColor: const Color(0xFFEF4444),
            inactiveTrackColor: const Color(0xFFEF4444).withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRating() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1630),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Text('Évaluation du client',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              final filled = idx <= _clientRating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _clientRating = idx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: filled ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled
                          ? (_clientRating <= 2 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))
                          : Colors.white.withOpacity(0.15),
                      size: 38,
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
              _clientRating == 0 ? 'Notez le client'
                  : _clientRating == 1 ? 'Très difficile'
                  : _clientRating == 2 ? 'Client difficile'
                  : _clientRating == 3 ? 'Client correct'
                  : _clientRating == 4 ? 'Bon client'
                  : 'Client excellent !',
              key: ValueKey(_clientRating),
              style: TextStyle(
                color: _clientRating == 0 ? Colors.white.withOpacity(0.2)
                    : _clientRating <= 2 ? const Color(0xFFEF4444)
                    : _clientRating >= 4 ? const Color(0xFFF59E0B)
                    : Colors.white.withOpacity(0.55),
                fontSize: 14, fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagGrid(String title, List<Map<String, dynamic>> tags,
      Set<String> selected, Color borderColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: tags.map((tag) {
            final sel = selected.contains(tag['label']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (sel) selected.remove(tag['label']);
                  else selected.add(tag['label'] as String);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? borderColor.withOpacity(0.12) : const Color(0xFF0D1630),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: sel ? borderColor : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tag['icon'] as IconData, size: 14,
                        color: sel ? textColor : Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 6),
                    Text(tag['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: sel ? textColor : Colors.white.withOpacity(0.4),
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
}