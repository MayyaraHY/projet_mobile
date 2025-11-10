import 'package:flutter/material.dart';
import '../models/rendez_vous.dart';
import '../services/rendez_vous_service.dart';

class RendezVousDetailsScreen extends StatefulWidget {
  final RendezVous rendezVous;

  const RendezVousDetailsScreen({
    super.key,
    required this.rendezVous,
  });

  @override
  State<RendezVousDetailsScreen> createState() => _RendezVousDetailsScreenState();
}

class _RendezVousDetailsScreenState extends State<RendezVousDetailsScreen> {
  final RendezVousService _rendezVousService = RendezVousService();
  late RendezVous _currentRendezVous;

  @override
  void initState() {
    super.initState();
    _currentRendezVous = widget.rendezVous;
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return Colors.orange;
      case 'confirme':
        return Colors.green;
      case 'annule':
        return Colors.red;
      case 'termine':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _changerStatut(String nouveauStatut) async {
    try {
      switch (nouveauStatut) {
        case 'confirme':
          await _rendezVousService.confirmerRendezVous(_currentRendezVous.id!);
          break;
        case 'annule':
          await _rendezVousService.annulerRendezVous(_currentRendezVous.id!);
          break;
        case 'termine':
          await _rendezVousService.terminerRendezVous(_currentRendezVous.id!);
          break;
      }

      // Recharger les données
      final updatedRendezVous = await _rendezVousService.obtenirRendezVousParId(_currentRendezVous.id!);
      if (updatedRendezVous != null) {
        setState(() {
          _currentRendezVous = updatedRendezVous;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _supprimerRendezVous() async {
    // Confirmer la suppression
    final bool? confirmer = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce rendez-vous ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmer == true) {
      try {
        await _rendezVousService.supprimerRendezVous(_currentRendezVous.id!);
        if (mounted) {
          Navigator.of(context).pop(); // Retourner à la liste
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendez-vous supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détails du Rendez-vous',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'supprimer') {
                _supprimerRendezVous();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'supprimer',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principale avec les informations du véhicule
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête véhicule
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 32,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentRendezVous.voitureMarque ?? 'N/A'} ${_currentRendezVous.voitureModele ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Matricule: ${_currentRendezVous.voitureMatricule ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentRendezVous.voiturePrix != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentRendezVous.voiturePrix!.toStringAsFixed(0)} €',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Statut actuel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatutColor(_currentRendezVous.statut).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatutColor(_currentRendezVous.statut),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatutColor(_currentRendezVous.statut),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Statut: ${RendezVousService.getLibelleStatut(_currentRendezVous.statut)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatutColor(_currentRendezVous.statut),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Informations du rendez-vous
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations du Rendez-vous',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(Icons.calendar_today, 'Date', _currentRendezVous.dateRendezVous),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.access_time, 'Heure', _currentRendezVous.heureRendezVous),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Lieu', _currentRendezVous.lieu),

                    if (_currentRendezVous.notes != null && _currentRendezVous.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.note, 'Notes', _currentRendezVous.notes!),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Actions selon le statut
            if (_currentRendezVous.statut == 'en_attente') ...[
              Text(
                'Actions disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _changerStatut('confirme'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _changerStatut('annule'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Annuler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_currentRendezVous.statut == 'confirme') ...[
              Text(
                'Actions disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _changerStatut('termine'),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Marquer comme terminé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}
