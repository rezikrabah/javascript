import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../gerant/profile_gerant.dart';

class ChauffeurScreen extends StatefulWidget {
  const ChauffeurScreen({Key? key}) : super(key: key);

  @override
  State<ChauffeurScreen> createState() => _ChauffeurScreenState();
}

class _ChauffeurScreenState extends State<ChauffeurScreen> {
  List<dynamic> _chauffeurs = [];
  bool _loading = true;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadChauffeurs();
  }

  Future<void> _loadChauffeurs() async {
    setState(() => _loading = true);
    final data = await ApiService.getMyChauffeurs();
    setState(() {
      _chauffeurs = data;
      _loading = false;
    });
  }

  Future<void> _deleteChauffeur(Map<String, dynamic> chauffeur, int index) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0B3C49) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          Text('Supprimer', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Voulez-vous vraiment supprimer ${chauffeur['prenom']} ${chauffeur['nom']} ?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Remove from gerant's chauffeurs array using the user's _id
      await ApiService.deleteChauffeur(chauffeur['_id'] ?? chauffeur['id']);

      setState(() {
        _chauffeurs.removeAt(index);
        if (_expandedIndex == index) _expandedIndex = -1;
        if (_expandedIndex > index) _expandedIndex--;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('${chauffeur['prenom']} ${chauffeur['nom']} retiré'),
          ]),
          backgroundColor: const Color(0xFF2979FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de la suppression'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF0F4FF),
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : const Color(0xFF1A237E)),
        title: Text('Mes Chauffeurs', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileGerantScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF0D4D5E) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white12 : Colors.black12)),
              child: const Icon(CupertinoIcons.person_crop_circle, color: Color(0xFF2979FF), size: 20),
            ),
          ),
          GestureDetector(
            onTap: _loadChauffeurs,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF0D4D5E) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white12 : Colors.black12)),
              child: const Icon(Icons.refresh, color: Color(0xFF2979FF), size: 20),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2979FF)))
          : Column(children: [
        // Header Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF2979FF)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildStat('${_chauffeurs.length}', 'Total'),
            _buildStat('${_chauffeurs.where((c) => c['isOnline'] == true).length}', 'En ligne'),
            _buildStat('${_chauffeurs.where((c) => c['isOnline'] != true).length}', 'Hors ligne'),
          ]),
        ),
        _chauffeurs.isEmpty
            ? Expanded(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline, size: 64, color: isDark ? Colors.white24 : Colors.black12),
              const SizedBox(height: 12),
              Text('Aucun chauffeur pour l\'instant',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
              const SizedBox(height: 6),
              Text('Partagez votre code aux chauffeurs',
                  style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12)),
            ]),
          ),
        )
            : Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: _chauffeurs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _buildChauffeurCard(_chauffeurs[i], i, isDark),
          ),
        ),
      ]),
    );
  }

  Widget _buildStat(String val, String label) => Column(children: [
    Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);

  Widget _buildChauffeurCard(Map<String, dynamic> c, int index, bool isDark) {
    final isExpanded = _expandedIndex == index;
    final isOnline = c['isOnline'] == true;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B3C49) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Row(children: [
            Stack(children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2979FF),
                child: Text(c['nom'][0], style: const TextStyle(color: Colors.white)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF0B3C49) : Colors.white, width: 1.5),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c['prenom']} ${c['nom']}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                Text(isOnline ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(fontSize: 11, color: isOnline ? Colors.green : Colors.grey)),
              ]),
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
          ]),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.phone, size: 15, color: Colors.grey),
              const SizedBox(width: 6),
              Text(c['telephone'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, size: 15, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(c['adresse'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 13))),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _deleteChauffeur(c, index),
                icon: const Icon(Icons.person_remove_outlined, size: 18, color: Colors.red),
                label: const Text('Retirer ce chauffeur', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}