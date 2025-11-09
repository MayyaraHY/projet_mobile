import 'package:flutter/material.dart';
import '../models/rendezvous.dart';
import '../services/rendezvous_service.dart';
import '../models/voiture.dart';
import '../services/voiture_service.dart';
import 'rendez_vous_details_screen.dart';

class RendezVousScreen extends StatefulWidget {
  const RendezVousScreen({super.key});

  @override
  State<RendezVousScreen> createState() => _RendezVousScreenState();
}

class _RendezVousScreenState extends State<RendezVousScreen> {
  final RendezVousService _rendezvousService = RendezVousService();
  final VoitureService _voitureService = VoitureService();
  List<RendezVous> _rendezvous = [];
  List<RendezVous> _filteredRendezVous = [];
  Map<String, Voiture> _voitureCache = {};
  bool _isLoading = true;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRendezVous();
  }

  Future<void> _loadRendezVous() async {
    setState(() => _isLoading = true);
    try {
      final rendezvous = await _rendezvousService.getAll();

      // Load voiture details for each rendezvous
      for (final rdv in rendezvous) {
        if (!_voitureCache.containsKey(rdv.voitureMatricule)) {
          try {
            final voiture = await _voitureService.getByMatricule(rdv.voitureMatricule);
            if (voiture != null) {
              _voitureCache[rdv.voitureMatricule] = voiture;
            }
          } catch (e) {
            print('Error loading voiture ${rdv.voitureMatricule}: $e');
          }
        }
      }

      setState(() {
        _rendezvous = rendezvous;
        _applyStatusFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
    }
  }

  void _applyStatusFilter() {
    if (_selectedStatusFilter == 'all') {
      _filteredRendezVous = List.from(_rendezvous);
    } else {
      _filteredRendezVous = _rendezvous.where((rdv) => rdv.status == _selectedStatusFilter).toList();
    }
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatusFilter = status;
      _applyStatusFilter();
    });
  }

  Future<void> _deleteRendezVous(int id) async {
    try {
      final success = await _rendezvousService.delete(id);
      if (success) {
        await _loadRendezVous(); // Reload the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous supprimé')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de supprimer le rendez-vous')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  Future<void> _navigateToDetails(RendezVous rendezvous) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RendezVousDetailsScreen(rendezvous: rendezvous),
      ),
    );

    // If changes were made, refresh the list
    if (result == true) {
      await _loadRendezVous();
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

  Widget _buildStatusChip(RendezVous rendezvous) {
    final color = _getStatusColor(rendezvous.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(rendezvous.status), color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            rendezvous.statusDisplayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRendezVousCard(RendezVous rendezvous) {
    final voiture = _voitureCache[rendezvous.voitureMatricule];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetails(rendezvous),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with voiture info and delete button
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voiture != null
                              ? '${voiture!.marque} ${voiture!.modele}'
                              : 'Véhicule ${rendezvous.voitureMatricule}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Matricule: ${rendezvous.voitureMatricule}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[400]),
                    onPressed: () => _showDeleteConfirmation(rendezvous),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status chip
              _buildStatusChip(rendezvous),

              const SizedBox(height: 16),

              // Date and time
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${rendezvous.date}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.access_time, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Heure: ${rendezvous.time}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lieu: ${rendezvous.lieu}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              // Notes (if available)
              if (rendezvous.notes != null && rendezvous.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: Colors.purple[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notes: ${rendezvous.notes}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Created date
              Text(
                'Créé le: ${_formatCreatedAt(rendezvous.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreatedAt(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }

  String _getFilterDisplayName(String status) {
    switch (status) {
      case RendezVous.statusPending:
        return 'en attente';
      case RendezVous.statusConfirmed:
        return 'confirmé';
      case RendezVous.statusCompleted:
        return 'terminé';
      case RendezVous.statusCancelled:
        return 'annulé';
      default:
        return status;
    }
  }

  void _showDeleteConfirmation(RendezVous rendezvous) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRendezVous(rendezvous.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    final filterOptions = [
      {'key': 'all', 'label': 'Tous', 'color': Colors.grey},
      {'key': RendezVous.statusPending, 'label': 'En attente', 'color': Colors.orange},
      {'key': RendezVous.statusConfirmed, 'label': 'Confirmé', 'color': Colors.blue},
      {'key': RendezVous.statusCompleted, 'label': 'Terminé', 'color': Colors.green},
      {'key': RendezVous.statusCancelled, 'label': 'Annulé', 'color': Colors.red},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final option = filterOptions[index];
          final isSelected = _selectedStatusFilter == option['key'];
          final color = option['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option['label'] as String),
              selected: isSelected,
              onSelected: (selected) => _onStatusFilterChanged(option['key'] as String),
              backgroundColor: Colors.white,
              selectedColor: color.withOpacity(0.2),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? color : Colors.grey[300]!,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rendezvous.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun rendez-vous planifié',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Planifiez un rendez-vous depuis la fiche d\'un véhicule',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Status filter chips
                    _buildStatusFilterChips(),

                    const SizedBox(height: 8),

                    // Rendez-vous list or empty state
                    Expanded(
                      child: _filteredRendezVous.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_list_off,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedStatusFilter == 'all'
                                        ? 'Aucun rendez-vous'
                                        : 'Aucun rendez-vous ${_getFilterDisplayName(_selectedStatusFilter)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedStatusFilter == 'all'
                                        ? 'Créez votre premier rendez-vous'
                                        : 'Essayez de changer le filtre',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadRendezVous,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _filteredRendezVous.length,
                                itemBuilder: (context, index) {
                                  return _buildRendezVousCard(_filteredRendezVous[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
