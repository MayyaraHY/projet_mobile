import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/voiture.dart';
import '../services/voiture_service.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final VoitureService _voitureService = VoitureService();
  List<Voiture> _myVoitures = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMyVoitures();
  }

  Future<void> _loadMyVoitures() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = await authService.getCurrentUser();
    
    if (currentUser == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final voitures = await _voitureService.getVoituresByUser(currentUser.uid);
      setState(() {
        _myVoitures = voitures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myVoitures.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Vous n\'avez pas encore d\'annonces',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  padding: const EdgeInsets.all(10),
                  itemCount: _myVoitures.length,
                  itemBuilder: (context, index) {
                    final voiture = _myVoitures[index];
                    return Card(
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: voiture.hasImage
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    child: Image.file(
                                      File(voiture.image!),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.blue,
                                          child: Center(
                                            child: Text(
                                              voiture.marque[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    color: Colors.blue,
                                    child: Center(
                                      child: Text(
                                        voiture.marque[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${voiture.marque} ${voiture.modele}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Matricule: ${voiture.matricule}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Année: ${voiture.annee}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (voiture.hasDescription)
                                    Text(
                                      voiture.description!.length > 30
                                          ? '${voiture.description!.substring(0, 30)}...'
                                          : voiture.description!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  voiture.prixFormate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.orange,
                                      onPressed: () {
                                        // Navigate back to main screen for editing
                                        Navigator.pop(context, {
                                          'action': 'edit',
                                          'voiture': voiture,
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.info_outline, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.blue,
                                      onPressed: () =>
                                          _showVoitureDetails(voiture),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.red,
                                      onPressed: () =>
                                          _deleteVoiture(voiture.matricule),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVoiture(String matricule) async {
    final confirmed = await _showConfirmDialog(
      'Confirmer la suppression',
      'Êtes-vous sûr de vouloir supprimer cette voiture?',
    );

    if (confirmed == true) {
      try {
        final result = await _voitureService.deleteVoiture(matricule);
        if (result) {
          _showSuccessSnackBar('Voiture supprimée avec succès');
          _loadMyVoitures();
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression: $e');
      }
    }
  }

  void _showVoitureDetails(Voiture voiture) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${voiture.marque} ${voiture.modele}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (voiture.hasImage)
                Image.file(
                  File(voiture.image!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text('Matricule: ${voiture.matricule}'),
              Text('Année: ${voiture.annee}'),
              Text('Kilométrage: ${voiture.kilometrage} km'),
              Text('Puissance: ${voiture.puissance} CV'),
              Text('Cylindres: ${voiture.cylindres}'),
              Text('Carburant: ${voiture.carburant}'),
              Text('Prix: ${voiture.prixFormate}'),
              if (voiture.hasDescription) ...[
                const SizedBox(height: 8),
                const Text('Description:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(voiture.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}