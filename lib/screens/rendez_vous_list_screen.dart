import 'package:flutter/material.dart';
import '../models/rendez_vous.dart';
import '../services/rendez_vous_service.dart';
import 'rendez_vous_details_screen.dart';

class RendezVousListScreen extends StatefulWidget {
  const RendezVousListScreen({super.key});

  @override
  State<RendezVousListScreen> createState() => _RendezVousListScreenState();
}

class _RendezVousListScreenState extends State<RendezVousListScreen> {
  final RendezVousService _rendezVousService = RendezVousService();
  List<RendezVous> _rendezVousList = [];
  bool _isLoading = true;
  String _selectedStatut = 'Tous';
  final List<String> _statutOptions = ['Tous', 'En attente', 'Confirmé', 'Annulé', 'Terminé'];

  @override
  void initState() {
    super.initState();
    _loadRendezVous();
  }

  Future<void> _loadRendezVous() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<RendezVous> rendezVousList;
      if (_selectedStatut == 'Tous') {
        rendezVousList = await _rendezVousService.obtenirTousLesRendezVous();
      } else {
        String statutCode = _getStatutCode(_selectedStatut);
        rendezVousList = await _rendezVousService.obtenirRendezVousParStatut(statutCode);
      }

      setState(() {
        _rendezVousList = rendezVousList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des rendez-vous: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatutCode(String libelle) {
    switch (libelle) {
      case 'En attente':
        return 'en_attente';
      case 'Confirmé':
        return 'confirme';
      case 'Annulé':
        return 'annule';
      case 'Terminé':
        return 'termine';
      default:
        return 'en_attente';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rendez-vous',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtres par statut
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statutOptions.length,
              itemBuilder: (context, index) {
                final statut = _statutOptions[index];
                final isSelected = _selectedStatut == statut;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(statut),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatut = statut;
                      });
                      _loadRendezVous();
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue[800] : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Liste des rendez-vous
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rendezVousList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun rendez-vous trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Planifiez un rendez-vous depuis la liste des voitures',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRendezVous,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rendezVousList.length,
                          itemBuilder: (context, index) {
                            final rendezVous = _rendezVousList[index];
                            return _buildRendezVousCard(rendezVous);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRendezVousCard(RendezVous rendezVous) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RendezVousDetailsScreen(rendezVous: rendezVous),
            ),
          ).then((_) => _loadRendezVous());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${rendezVous.voitureMarque ?? 'N/A'} ${rendezVous.voitureModele ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatutColor(rendezVous.statut),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      RendezVousService.getLibelleStatut(rendezVous.statut),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations du véhicule
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Matricule: ${rendezVous.voitureMatricule ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (rendezVous.voiturePrix != null)
                    Text(
                      '${rendezVous.voiturePrix!.toStringAsFixed(0)} €',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Date et heure
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    rendezVous.dateRendezVous,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    rendezVous.heureRendezVous,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Lieu
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rendezVous.lieu,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              // Notes si disponibles
              if (rendezVous.notes != null && rendezVous.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rendezVous.notes!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
