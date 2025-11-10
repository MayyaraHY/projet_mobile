import 'dart:io';
import 'package:flutter/material.dart';
import '../models/voiture.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import 'package:provider/provider.dart';

class VoitureDetailsScreen extends StatefulWidget {
  final Voiture voiture;

  const VoitureDetailsScreen({Key? key, required this.voiture}) : super(key: key);

  @override
  State<VoitureDetailsScreen> createState() => _VoitureDetailsScreenState();
}

// Small dialog to submit a rating for a seller
class _RatingDialog extends StatefulWidget {
  final String sellerId;
  final String raterId;

  const _RatingDialog({Key? key, required this.sellerId, required this.raterId}) : super(key: key);

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Noter le vendeur'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                icon: Icon(idx <= _rating ? Icons.star : Icons.star_border, color: Colors.amber),
                onPressed: () => setState(() => _rating = idx),
              );
            }),
          ),
          TextField(
            controller: _commentCtrl,
            decoration: const InputDecoration(labelText: 'Commentaire (optionnel)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await RatingService().addRating(
                      sellerId: widget.sellerId,
                      raterId: widget.raterId,
                      rating: _rating,
                      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
                    );
                    Navigator.pop(context, true);
                  } catch (e) {
                    setState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                },
          child: _loading ? const CircularProgressIndicator() : const Text('Envoyer'),
        ),
      ],
    );
  }
}

class _VoitureDetailsScreenState extends State<VoitureDetailsScreen> {
  UserModel? _seller;
  bool _isLoading = true;
  bool _isRating = false;

  @override
  void initState() {
    super.initState();
    _loadSellerDetails();
  }

  Future<void> _loadSellerDetails() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final seller = await auth.getUserById(widget.voiture.ownerId!);
    setState(() {
      _seller = seller;
      _isLoading = false;
    });
  }

  Future<void> _showRatingDialog() async {
    if (_seller == null) return;

    final currentUser = await Provider.of<AuthService>(context, listen: false).getCurrentUser();
    if (currentUser == null) return;

    setState(() => _isRating = true);
    await showDialog(
      context: context,
      builder: (context) => _RatingDialog(sellerId: _seller!.uid, raterId: currentUser.uid),
    );
    await _loadSellerDetails(); // Reload to get updated rating
    setState(() => _isRating = false);
  }

  Widget _buildSellerInfo() {
    if (_seller == null) return const SizedBox.shrink();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _seller?.photoPath != null
              ? FileImage(File(_seller!.photoPath!))
              : null,
          child: _seller?.photoPath == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Row(
          children: [
            Text(_seller!.displayName),
            if (_seller!.isNewSeller) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'New Seller',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_seller?.phoneNumber != null)
              Text('Phone: ${_seller!.phoneNumber}'),
            if (_seller?.rating != null)
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  Text(' ${_seller!.rating!.toStringAsFixed(1)} '),
                  Text('(${_seller!.totalRatings} ratings)'),
                ],
              ),
          ],
        ),
        trailing: Provider.of<AuthService>(context).currentUid != _seller!.uid
            ? IconButton(
                icon: _isRating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.star_border),
                onPressed: _isRating ? null : _showRatingDialog,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiture = widget.voiture;

    return Scaffold(
      appBar: AppBar(
        title: Text('${voiture.marque} ${voiture.modele}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (voiture.hasImage)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.file(
                          File(voiture.image!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.directions_car, size: 64),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voiture.prixFormate,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Matricule', voiture.matricule),
                          _buildInfoRow('Année', voiture.annee.toString()),
                          _buildInfoRow('Puissance', '${voiture.puissance} ch'),
                          _buildInfoRow('Cylindres', voiture.cylindres.toString()),
                          _buildInfoRow('Carburant', voiture.carburant),
                          _buildInfoRow('Kilométrage', '${voiture.kilometrage} km'),
                          if (voiture.hasDescription) ...[
                            const Divider(),
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(voiture.description!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSellerInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}