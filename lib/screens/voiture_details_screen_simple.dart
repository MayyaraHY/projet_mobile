import 'dart:io';
import 'package:flutter/material.dart';
import '../models/voiture.dart';
import 'planifier_rendez_vous_screen.dart';

class VoitureDetailsScreenSimple extends StatelessWidget {
  final Voiture voiture;

  const VoitureDetailsScreenSimple({super.key, required this.voiture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${voiture.marque} ${voiture.modele}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: voiture.image != null && voiture.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: File(voiture.image!).existsSync()
                          ? Image.file(
                              File(voiture.image!),
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.directions_car,
                              size: 80,
                              color: Colors.grey,
                            ),
                    )
                  : const Icon(
                      Icons.directions_car,
                      size: 80,
                      color: Colors.grey,
                    ),
            ),

            const SizedBox(height: 20),

            // Title and price
            Text(
              '${voiture.marque} ${voiture.modele}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              voiture.prixFormate,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),

            const SizedBox(height: 20),

            // Vehicle details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails du véhicule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Matricule', voiture.matricule),
                    _buildDetailRow('Marque', voiture.marque),
                    _buildDetailRow('Modèle', voiture.modele),
                    _buildDetailRow('Année', voiture.annee.toString()),
                    _buildDetailRow('Puissance', '${voiture.puissance} ch'),
                    _buildDetailRow('Cylindres', voiture.cylindres.toString()),
                    _buildDetailRow('Carburant', voiture.carburant),
                    _buildDetailRow('Kilométrage', '${voiture.kilometrage.toStringAsFixed(0)} km'),
                    if (voiture.description != null && voiture.description!.isNotEmpty)
                      _buildDetailRow('Description', voiture.description!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlanifierRendezVousScreen(voiture: voiture),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_note),
                    label: const Text('Planifier un Rendez-vous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Handle offer action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à implémenter'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('Faire une offre'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
