import 'package:flutter/material.dart';

import '../services/api_service.dart';

// ─────────────────────────────────────────
//  MODÈLE
// ─────────────────────────────────────────
enum NiveauPenurie { legere, moderee, grave }

extension NiveauLabel on NiveauPenurie {
  String get label {
    switch (this) {
      case NiveauPenurie.legere:
        return 'Légère';
      case NiveauPenurie.moderee:
        return 'Modérée';
      case NiveauPenurie.grave:
        return 'Grave';
    }
  }

  String get description {
    switch (this) {
      case NiveauPenurie.legere:
        return 'Quelques heures';
      case NiveauPenurie.moderee:
        return '1 à 2 jours';
      case NiveauPenurie.grave:
        return '+3 jours';
    }
  }

  Color get couleur {
    switch (this) {
      case NiveauPenurie.legere:
        return const Color(0xFF639922);
      case NiveauPenurie.moderee:
        return const Color(0xFFBA7517);
      case NiveauPenurie.grave:
        return const Color(0xFFA32D2D);
    }
  }

  Color get couleurFond {
    switch (this) {
      case NiveauPenurie.legere:
        return const Color(0xFFEAF3DE);
      case NiveauPenurie.moderee:
        return const Color(0xFFFAEEDA);
      case NiveauPenurie.grave:
        return const Color(0xFFFCEBEB);
    }
  }
}

// ─────────────────────────────────────────
//  ÉCRAN PRINCIPAL CLIENT
// ─────────────────────────────────────────
class ClientInfoScreen extends StatefulWidget {
  const ClientInfoScreen({super.key});

  @override
  State<ClientInfoScreen> createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quartierCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _commentaireCtrl = TextEditingController();

  NiveauPenurie? _niveauSelectionne;
  int _dureeNombre = 1;
  String _dureeUnite = 'jours';
  bool _submitted = false;

  final List<String> _unites = ['heures', 'jours', 'semaines'];

  @override
  void dispose() {
    _quartierCtrl.dispose();
    _communeCtrl.dispose();
    _commentaireCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _niveauSelectionne == null) {
      if (_niveauSelectionne == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un niveau de pénurie.'),
            backgroundColor: Color(0xFFA32D2D),
          ),
        );
      }
      return;
    }

    // Map enum → string the backend expects
    final niveauStr = _niveauSelectionne!.name; // 'legere' | 'moderee' | 'grave'

    final result = await ApiService.addSignalement(
      quartier:    _quartierCtrl.text.trim(),
      commune:     _communeCtrl.text.trim(),
      niveau:      niveauStr,
      dureeNombre: _dureeNombre,
      dureeUnite:  _dureeUnite,
      commentaire: _commentaireCtrl.text.trim(),
    );

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${result['error']}'),
          backgroundColor: const Color(0xFFA32D2D),
        ),
      );
    } else {
      setState(() => _submitted = true);
    }
  }

  void _reset() {
    setState(() {
      _submitted = false;
      _niveauSelectionne = null;
      _dureeNombre = 1;
      _dureeUnite = 'jours';
      _quartierCtrl.clear();
      _communeCtrl.clear();
      _commentaireCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.water_drop_outlined, color: Color(0xFF185FA5)),
        title: const Text(
          'Signaler une pénurie',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE0E0E0), height: 0.5),
        ),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  // ── FORMULAIRE ──────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Votre localisation'),
          const SizedBox(height: 8),
          _buildCard(
            children: [
              _buildTextField(
                controller: _quartierCtrl,
                label: 'Quartier / Zone',
                hint: 'Ex : Cité des fleurs, Bloc B',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _communeCtrl,
                label: 'Commune',
                hint: 'Ex : M\'Sila, El Hamel...',
                icon: Icons.map_outlined,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Niveau de pénurie'),
          const SizedBox(height: 8),
          _buildCard(
            children: [
              Row(
                children: NiveauPenurie.values
                    .map((n) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: n != NiveauPenurie.grave ? 8 : 0,
                    ),
                    child: _NiveauButton(
                      niveau: n,
                      selected: _niveauSelectionne == n,
                      onTap: () =>
                          setState(() => _niveauSelectionne = n),
                    ),
                  ),
                ))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Durée estimée sans eau'),
          const SizedBox(height: 8),
          _buildCard(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombre',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _DureeCounter(
                          value: _dureeNombre,
                          onChanged: (v) => setState(() => _dureeNombre = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unité',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Commentaire libre'),
          const SizedBox(height: 8),
          _buildCard(
            children: [
              TextFormField(
                controller: _commentaireCtrl,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                  'Ex : L\'eau coupe chaque soir à partir de 18h...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF185FA5)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF185FA5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Transmettre l\'information',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── SUCCÈS ──────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3DE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: Color(0xFF3B6D11),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Information transmise !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les conducteurs ont été notifiés de la situation dans votre zone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF185FA5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Nouveau signalement',
                style: TextStyle(color: Color(0xFF185FA5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ─────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF888888)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF185FA5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFA32D2D)),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _dureeUnite,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          items: _unites
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: (v) => setState(() => _dureeUnite = v!),
        ),
      ),
    );
  }
}

// ── WIDGET BOUTON NIVEAU ─────────────────
class _NiveauButton extends StatelessWidget {
  final NiveauPenurie niveau;
  final bool selected;
  final VoidCallback onTap;

  const _NiveauButton({
    required this.niveau,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? niveau.couleurFond : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? niveau.couleur : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: niveau.couleur,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              niveau.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? niveau.couleur : const Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              niveau.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WIDGET COMPTEUR DURÉE ────────────────
class _DureeCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DureeCounter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        children: [
          _CounterBtn(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          _CounterBtn(
            icon: Icons.add,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? const Color(0xFF185FA5)
              : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}