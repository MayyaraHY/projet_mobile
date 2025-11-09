import 'package:flutter/material.dart';
import '../models/rendezvous.dart';
import '../models/voiture.dart';
import '../services/rendezvous_service.dart';
import '../services/voiture_service.dart';

class RendezVousDetailsScreen extends StatefulWidget {
  final RendezVous rendezvous;

  const RendezVousDetailsScreen({super.key, required this.rendezvous});

  @override
  State<RendezVousDetailsScreen> createState() => _RendezVousDetailsScreenState();
}

class _RendezVousDetailsScreenState extends State<RendezVousDetailsScreen> {
  final RendezVousService _rendezvousService = RendezVousService();
  final VoitureService _voitureService = VoitureService();

  late RendezVous _currentRendezVous;
  Voiture? _voiture;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentRendezVous = widget.rendezvous;
    _loadVoitureDetails();
  }

  Future<void> _loadVoitureDetails() async {
    setState(() => _isLoading = true);
    try {
      final voiture = await _voitureService.getByMatricule(_currentRendezVous.voitureMatricule);
      setState(() {
        _voiture = voiture;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final success = await _rendezvousService.updateStatus(_currentRendezVous.id!, newStatus);
      if (success) {
        setState(() {
          _currentRendezVous = _currentRendezVous.copyWith(status: newStatus);
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour: ${_currentRendezVous.statusDisplayName}')),
        );
      } else {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de mettre à jour le statut')),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deleteRendezVous() async {
    setState(() => _isUpdating = true);
    try {
      final success = await _rendezvousService.delete(_currentRendezVous.id!);
      if (success) {
        // Navigate back with indication that item was deleted
        Navigator.of(context).pop(true);
        // The success message will be shown in the parent screen
      } else {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de supprimer le rendez-vous')),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  void _showDeleteConfirmation() {
    final carInfo = _voiture != null
        ? '${_voiture!.marque} ${_voiture!.modele}'
        : 'ce véhicule';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: Text('Êtes-vous sûr de vouloir supprimer le rendez-vous pour $carInfo prévu le ${_currentRendezVous.date} à ${_currentRendezVous.time} ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRendezVous();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RendezVous.validStatuses.map((status) {
            final isSelected = status == _currentRendezVous.status;
            return ListTile(
              title: Text(_getStatusDisplayName(status)),
              leading: Radio<String>(
                value: status,
                groupValue: _currentRendezVous.status,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null && value != _currentRendezVous.status) {
                    _updateStatus(value);
                  }
                },
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case RendezVous.statusPending:
        return 'En attente';
      case RendezVous.statusConfirmed:
        return 'Confirmé';
      case RendezVous.statusCompleted:
        return 'Terminé';
      case RendezVous.statusCancelled:
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case RendezVous.statusPending:
        return Colors.orange;
      case RendezVous.statusConfirmed:
        return Colors.blue;
      case RendezVous.statusCompleted:
        return Colors.green;
      case RendezVous.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case RendezVous.statusPending:
        return Icons.schedule;
      case RendezVous.statusConfirmed:
        return Icons.check_circle_outline;
      case RendezVous.statusCompleted:
        return Icons.check_circle;
      case RendezVous.statusCancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatCreatedAt(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }

  Widget _buildStatusChip() {
    final color = _getStatusColor(_currentRendezVous.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(_currentRendezVous.status), color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            _currentRendezVous.statusDisplayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_voiture != null
            ? '${_voiture!.marque} ${_voiture!.modele}'
            : 'Détails du Rendez-vous'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isUpdating)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Supprimer le rendez-vous',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statut du rendez-vous',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(child: _buildStatusChip()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Vehicle Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Véhicule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.directions_car, color: Colors.blue[600], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _voiture != null
                                          ? '${_voiture!.marque} ${_voiture!.modele}'
                                          : 'Véhicule ${_currentRendezVous.voitureMatricule}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Matricule: ${_currentRendezVous.voitureMatricule}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (_voiture != null)
                                      Text(
                                        'Prix: ${_voiture!.prixFormate}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Appointment Details Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails du rendez-vous',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date and time
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.green[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _currentRendezVous.date,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Icon(Icons.access_time, color: Colors.orange[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Heure',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _currentRendezVous.time,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, color: Colors.red[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lieu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _currentRendezVous.lieu,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Notes (if available)
                          if (_currentRendezVous.notes != null && _currentRendezVous.notes!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note, color: Colors.purple[600], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _currentRendezVous.notes!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Created date
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.grey[500], size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Créé le: ${_formatCreatedAt(_currentRendezVous.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _showStatusDialog,
                      icon: _isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.edit_calendar),
                      label: Text(_isUpdating ? 'Mise à jour...' : 'Modifier le statut'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
