import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/voiture.dart';
import '../services/voiture_service.dart';

class VoitureListScreen extends StatefulWidget {
  const VoitureListScreen({Key? key}) : super(key: key);

  @override
  State<VoitureListScreen> createState() => _VoitureListScreenState();
}

class _VoitureListScreenState extends State<VoitureListScreen> {
  final VoitureService _voitureService = VoitureService();
  List<Voiture> _voitures = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVoitures();
  }

  Future<void> _loadVoitures() async {
    setState(() => _isLoading = true);
    try {
      final voitures = await _voitureService.getAllVoitures();
      setState(() {
        _voitures = voitures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  Future<void> _searchVoitures(String query) async {
    setState(() => _isLoading = true);
    try {
      final voitures = await _voitureService.searchVoitures(query);
      setState(() {
        _voitures = voitures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors de la recherche: $e');
    }
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
          _loadVoitures();
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression: $e');
      }
    }
  }

  void _showAddVoitureDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVoitureDialog(
        onVoitureAdded: () {
          _loadVoitures();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditVoitureDialog(Voiture voiture) {
    showDialog(
      context: context,
      builder: (context) => EditVoitureDialog(
        voiture: voiture,
        onVoitureUpdated: () {
          _loadVoitures();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showVoitureDetails(Voiture voiture) {
    showDialog(
      context: context,
      builder: (context) => VoitureDetailsDialog(voiture: voiture),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Voitures'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVoitures,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par marque, modèle ou matricule...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.isEmpty) {
                  _loadVoitures();
                } else {
                  _searchVoitures(value);
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _voitures.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune voiture trouvée',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _voitures.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final voiture = _voitures[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: voiture.hasImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(voiture.image!),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            child: Text(
                                              voiture.marque[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        voiture.marque[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              title: Text(
                                '${voiture.marque} ${voiture.modele}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Matricule: ${voiture.matricule}'),
                                  Text('Année: ${voiture.annee}'),
                                  if (voiture.hasDescription)
                                    Text(
                                      voiture.description!.length > 30
                                          ? '${voiture.description!.substring(0, 30)}...'
                                          : voiture.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  Text('Prix: ${voiture.prixFormate}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      )),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.orange,
                                    onPressed: () =>
                                        _showEditVoitureDialog(voiture),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    color: Colors.blue,
                                    onPressed: () =>
                                        _showVoitureDetails(voiture),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () =>
                                        _deleteVoiture(voiture.matricule),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVoitureDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Dialog pour ajouter une voiture
class AddVoitureDialog extends StatefulWidget {
  final VoidCallback onVoitureAdded;

  const AddVoitureDialog({Key? key, required this.onVoitureAdded})
      : super(key: key);

  @override
  State<AddVoitureDialog> createState() => _AddVoitureDialogState();
}

class _AddVoitureDialogState extends State<AddVoitureDialog> {
  final _formKey = GlobalKey<FormState>();
  final VoitureService _voitureService = VoitureService();

  final _matriculeController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _anneeController = TextEditingController();
  final _puissanceController = TextEditingController();
  final _cylindresController = TextEditingController();
  final _kilometrageController = TextEditingController();
  final _prixController = TextEditingController();
  final _descriptionController = TextEditingController(); // NEW

  String _selectedCarburant = 'Essence';
  bool _isLoading = false;
  String? _selectedImagePath; // NEW

  @override
  void dispose() {
    _matriculeController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _puissanceController.dispose();
    _cylindresController.dispose();
    _kilometrageController.dispose();
    _prixController.dispose();
    _descriptionController.dispose(); // NEW
    super.dispose();
  }

  // NEW - Pick image from file system
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveVoiture() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _voitureService.createVoiture(
          matricule: _matriculeController.text,
          marque: _marqueController.text,
          modele: _modeleController.text,
          annee: int.parse(_anneeController.text),
          puissance: double.parse(_puissanceController.text),
          cylindres: int.parse(_cylindresController.text),
          carburant: _selectedCarburant,
          kilometrage: double.parse(_kilometrageController.text),
          prix: double.parse(_prixController.text),
          description: _descriptionController.text.isEmpty 
              ? null 
              : _descriptionController.text, // NEW
          image: _selectedImagePath, // NEW
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voiture ajoutée avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onVoitureAdded();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une voiture'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Image picker section
              if (_selectedImagePath != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImagePath!),
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() => _selectedImagePath = null);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_selectedImagePath == null 
                    ? 'Sélectionner une image'
                    : 'Changer l\'image'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matriculeController,
                decoration: const InputDecoration(labelText: 'Matricule'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _marqueController,
                decoration: const InputDecoration(labelText: 'Marque'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(labelText: 'Modèle'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _anneeController,
                decoration: const InputDecoration(labelText: 'Année'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _puissanceController,
                decoration: const InputDecoration(labelText: 'Puissance (CV)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _cylindresController,
                decoration: const InputDecoration(labelText: 'Cylindres'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCarburant,
                decoration: const InputDecoration(labelText: 'Carburant'),
                items: _voitureService
                    .getCarburantTypes()
                    .map((carburant) => DropdownMenuItem(
                          value: carburant,
                          child: Text(carburant),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCarburant = value!);
                },
              ),
              TextFormField(
                controller: _kilometrageController,
                decoration: const InputDecoration(labelText: 'Kilométrage'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(labelText: 'Prix (TND)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              // NEW - Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Ex: Bon état, première main...',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveVoiture,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// Dialog pour afficher les détails d'une voiture
class VoitureDetailsDialog extends StatelessWidget {
  final Voiture voiture;

  const VoitureDetailsDialog({Key? key, required this.voiture})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${voiture.marque} ${voiture.modele}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Image display
            if (voiture.hasImage)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(voiture.image!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              ),
            _buildDetailRow('Matricule', voiture.matricule),
            _buildDetailRow('Marque', voiture.marque),
            _buildDetailRow('Modèle', voiture.modele),
            _buildDetailRow('Année', voiture.annee.toString()),
            _buildDetailRow('Puissance', '${voiture.puissance} CV'),
            _buildDetailRow('Cylindres', voiture.cylindres.toString()),
            _buildDetailRow('Carburant', voiture.carburant),
            _buildDetailRow('Kilométrage', voiture.kilometrageFormate),
            _buildDetailRow('Prix', voiture.prixFormate, highlight: true),
            // Description
            if (voiture.hasDescription) ...[
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  voiture.description!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.green : Colors.black,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog pour modifier une voiture
class EditVoitureDialog extends StatefulWidget {
  final Voiture voiture;
  final VoidCallback onVoitureUpdated;

  const EditVoitureDialog({
    Key? key,
    required this.voiture,
    required this.onVoitureUpdated,
  }) : super(key: key);

  @override
  State<EditVoitureDialog> createState() => _EditVoitureDialogState();
}

class _EditVoitureDialogState extends State<EditVoitureDialog> {
  final _formKey = GlobalKey<FormState>();
  final VoitureService _voitureService = VoitureService();

  late final TextEditingController _marqueController;
  late final TextEditingController _modeleController;
  late final TextEditingController _anneeController;
  late final TextEditingController _puissanceController;
  late final TextEditingController _cylindresController;
  late final TextEditingController _kilometrageController;
  late final TextEditingController _prixController;
  late final TextEditingController _descriptionController;

  late String _selectedCarburant;
  bool _isLoading = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values
    _marqueController = TextEditingController(text: widget.voiture.marque);
    _modeleController = TextEditingController(text: widget.voiture.modele);
    _anneeController = TextEditingController(text: widget.voiture.annee.toString());
    _puissanceController = TextEditingController(text: widget.voiture.puissance.toString());
    _cylindresController = TextEditingController(text: widget.voiture.cylindres.toString());
    _kilometrageController = TextEditingController(text: widget.voiture.kilometrage.toString());
    _prixController = TextEditingController(text: widget.voiture.prix.toString());
    _descriptionController = TextEditingController(text: widget.voiture.description ?? '');
    _selectedCarburant = widget.voiture.carburant;
    _selectedImagePath = widget.voiture.image;
  }

  @override
  void dispose() {
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _puissanceController.dispose();
    _cylindresController.dispose();
    _kilometrageController.dispose();
    _prixController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateVoiture() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedVoiture = widget.voiture.copyWith(
          marque: _marqueController.text,
          modele: _modeleController.text,
          annee: int.parse(_anneeController.text),
          puissance: double.parse(_puissanceController.text),
          cylindres: int.parse(_cylindresController.text),
          carburant: _selectedCarburant,
          kilometrage: double.parse(_kilometrageController.text),
          prix: double.parse(_prixController.text),
          description: _descriptionController.text.isEmpty 
              ? null 
              : _descriptionController.text,
          image: _selectedImagePath,
        );

        await _voitureService.updateVoiture(updatedVoiture);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voiture mise à jour avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onVoitureUpdated();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier ${widget.voiture.marque} ${widget.voiture.modele}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker section
                if (_selectedImagePath != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImagePath!),
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() => _selectedImagePath = null);
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_selectedImagePath == null 
                      ? 'Sélectionner une image'
                      : 'Changer l\'image'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 16),
                // Matricule (non-editable)
                TextFormField(
                  initialValue: widget.voiture.matricule,
                  decoration: const InputDecoration(
                    labelText: 'Matricule',
                    enabled: false,
                  ),
                  enabled: false,
                ),
                TextFormField(
                  controller: _marqueController,
                  decoration: const InputDecoration(labelText: 'Marque'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _modeleController,
                  decoration: const InputDecoration(labelText: 'Modèle'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _anneeController,
                  decoration: const InputDecoration(labelText: 'Année'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _puissanceController,
                  decoration: const InputDecoration(labelText: 'Puissance (CV)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _cylindresController,
                  decoration: const InputDecoration(labelText: 'Cylindres'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCarburant,
                  decoration: const InputDecoration(labelText: 'Carburant'),
                  items: _voitureService
                      .getCarburantTypes()
                      .map((carburant) => DropdownMenuItem(
                            value: carburant,
                            child: Text(carburant),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCarburant = value!);
                  },
                ),
                TextFormField(
                  controller: _kilometrageController,
                  decoration: const InputDecoration(labelText: 'Kilométrage'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _prixController,
                  decoration: const InputDecoration(labelText: 'Prix (TND)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    hintText: 'Ex: Bon état, première main...',
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateVoiture,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mettre à jour'),
        ),
      ],
    );
  }
}
