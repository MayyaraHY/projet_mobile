import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/voiture.dart';
import '../services/voiture_service.dart';
import '../screens/voiture_details_screen.dart';
import '../screens/rendez_vous_screen.dart';


class VoitureListScreen extends StatefulWidget {
  const VoitureListScreen({super.key});

  @override
  State<VoitureListScreen> createState() => _VoitureListScreenState();
}

class _VoitureListScreenState extends State<VoitureListScreen> {
  final VoitureService _voitureService = VoitureService();
  List<Voiture> _voitures = [];
  bool _isLoading = true;
  String _selectedBrand = 'All';
  final List<String> _brands = ['All', 'Mercedes', 'Tesla', 'BMW', 'Audi', 'Ferrari'];

  // --- For chip carousel arrows ---
  final ScrollController _chipScrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  @override
  void initState() {
    super.initState();
    // Add listener for scroll arrows
    _chipScrollController.addListener(_updateArrowVisibility);
    // Check visibility after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrowVisibility());
    _loadVoitures();
  }

  @override
  void dispose() {
    // Dispose scroll controller
    _chipScrollController.removeListener(_updateArrowVisibility);
    _chipScrollController.dispose();
    super.dispose();
  }

  // Helper method to update arrow visibility
  void _updateArrowVisibility() {
    if (!_chipScrollController.hasClients) return;
    final position = _chipScrollController.position;
    bool atStart = position.pixels <= position.minScrollExtent;
    bool atEnd = position.pixels >= position.maxScrollExtent;
    bool listIsScrollable = position.maxScrollExtent > position.minScrollExtent;

    setState(() {
      _showLeftArrow = listIsScrollable && !atStart;
      _showRightArrow = listIsScrollable && !atEnd;
    });
  }

  // Helper method to scroll the chip list
  void _scrollChips({required bool isScrollingRight}) {
    final double scrollAmount = 200; // Amount to scroll
    final double currentPosition = _chipScrollController.position.pixels;
    final double newPosition = isScrollingRight
        ? currentPosition + scrollAmount
        : currentPosition - scrollAmount;

    _chipScrollController.animateTo(
      newPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadVoitures() async {
    setState(() {
      _isLoading = true;
      _selectedBrand = 'All'; 
    });
    try {
      final voitures = await _voitureService.getAllVoitures();
      setState(() {
        _voitures = voitures;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrowVisibility());
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  Future<void> _searchVoitures(String query) async {
    setState(() {
      _isLoading = true;
      _selectedBrand = query; 
    });
    try {
      final voitures = await _voitureService.searchVoitures(query);
      setState(() {
        _voitures = voitures;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrowVisibility());
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors de la recherche: $e');
    }
  }

  Future<void> _deleteVoiture(String matricule) async {
    final confirmed = await _showConfirmDialog(
      'Confirm Deletion',
      'Are you sure you want to delete this car?',
    );

    if (confirmed == true) {
      try {
        final result = await _voitureService.deleteVoiture(matricule);
        if (result) {
          _showSuccessSnackBar('Car deleted successfully');
          if (_selectedBrand == 'All') {
            _loadVoitures();
          } else {
            _searchVoitures(_selectedBrand);
          }
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting: $e');
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
          if (_selectedBrand == 'All') {
            _loadVoitures();
          } else {
            _searchVoitures(_selectedBrand);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showVoitureDetails(Voiture voiture) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoitureDetailsScreen(voiture: voiture),
      ),
    );
  }

  void _showAdminActionsSheet(Voiture voiture) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${voiture.marque} ${voiture.modele}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit Car'),
                onTap: () {
                  Navigator.pop(context); 
                  _showEditVoitureDialog(voiture);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Car'),
                onTap: () {
                  Navigator.pop(context); 
                  _deleteVoiture(voiture.matricule);
                },
              ),
            ],
          ),
        );
      },
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
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

  // This widget builds *only* the scrolling list of chips
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      controller: _chipScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Padding for the first item
          const SizedBox(width: 16),
          ..._brands.map((brand) {
            final isSelected = brand == _selectedBrand;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                constraints: const BoxConstraints(minWidth: 90),
                child: ChoiceChip(
                  label: Center(child: Text(brand)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      if (brand == 'All') {
                        _loadVoitures();
                      } else {
                        _searchVoitures(brand);
                      }
                    }
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.black,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  pressElevation: 0,
                ),
              ),
            );
          }),
          // Padding for the last item
          const SizedBox(width: 8), // (16 - 8 from previous item)
        ],
      ),
    );
  }

  Widget _buildCarGridItem(Voiture voiture) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showVoitureDetails(voiture),
        onLongPress: () => _showAdminActionsSheet(voiture),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: voiture.hasImage
                  ? Hero(
                      tag: 'voiture-img-${voiture.matricule}',
                      child: Image.file(
                        File(voiture.image!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImageErrorPlaceholder(),
                      ),
                    )
                  : _buildImageErrorPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                  _buildConditionTag(voiture),
                  const SizedBox(height: 8),
                  Text(
                    voiture.prixFormate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.directions_car,
        size: 50,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildConditionTag(Voiture voiture) {
    final bool isNew = voiture.kilometrage < 1000;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNew ? Colors.blue[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isNew ? 'New' : 'Used',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isNew ? Colors.blue[700] : Colors.grey[700],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text('Top Deals'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RendezVousScreen(),
                ),
              );
            },
            tooltip: 'Mes rendez-vous',
          ),
        ],
      ),
      body: Column(
        children: [
          // This Row holds the arrows and the chip list
          Row(
            children: [
              // Left Arrow
              Visibility(
                visible: _showLeftArrow,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => _scrollChips(isScrollingRight: false),
                ),
              ),
              // Chip List
              Expanded(
                child: _buildFilterChips(),
              ),
              // Right Arrow
              Visibility(
                visible: _showRightArrow,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: () => _scrollChips(isScrollingRight: true),
                ),
              ),
            ],
          ),

          // This is the main grid of cars
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _voitures.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No cars found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _voitures.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.70,
                        ),
                        itemBuilder: (context, index) {
                          final voiture = _voitures[index];
                          return _buildCarGridItem(voiture);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVoitureDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Car'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// --- AddVoitureDialog ---

class AddVoitureDialog extends StatefulWidget {
  final VoidCallback onVoitureAdded;

  const AddVoitureDialog({super.key, required this.onVoitureAdded});

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
  final _descriptionController = TextEditingController();

  String _selectedCarburant = 'Essence';
  bool _isLoading = false;
  String? _selectedImagePath;

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
            content: Text('Error picking image: $e'),
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
              : _descriptionController.text,
          image: _selectedImagePath,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Car added successfully!'),
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
              content: Text('Error: $e'),
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
      title: const Text('Add a new car'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    ? 'Select image'
                    : 'Change image'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matriculeController,
                decoration: const InputDecoration(labelText: 'Matricule'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              TextFormField(
                controller: _marqueController,
                decoration: const InputDecoration(labelText: 'Brand (Marque)'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              TextFormField(
                controller: _anneeController,
                decoration: const InputDecoration(labelText: 'Year (Année)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              TextFormField(
                controller: _puissanceController,
                decoration: const InputDecoration(labelText: 'Power (CV)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              TextFormField(
                controller: _cylindresController,
                decoration: const InputDecoration(labelText: 'Cylinders'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedCarburant,
                decoration: const InputDecoration(labelText: 'Fuel (Carburant)'),
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
                decoration: const InputDecoration(labelText: 'Kilometrage'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(labelText: 'Price (TND)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Ex: Good condition, first owner...',
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveVoiture,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// --- EditVoitureDialog ---

class EditVoitureDialog extends StatefulWidget {
  final Voiture voiture;
  final VoidCallback onVoitureUpdated;

  const EditVoitureDialog({
    super.key,
    required this.voiture,
    required this.onVoitureUpdated,
  });

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
            content: Text('Error picking image: $e'),
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
              content: Text('Car updated successfully!'),
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
              content: Text('Error: $e'),
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
      title: Text('Edit ${widget.voiture.marque} ${widget.voiture.modele}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      ? 'Select image'
                      : 'Change image'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 16),
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
                  decoration: const InputDecoration(labelText: 'Brand (Marque)'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Field required' : null,
                ),
                TextFormField(
                  controller: _modeleController,
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Field required' : null,
                ),
                TextFormField(
                  controller: _anneeController,
                  decoration: const InputDecoration(labelText: 'Year (Année)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Field required' : null,
                ),
                TextFormField(
                  controller: _puissanceController,
                  decoration: const InputDecoration(labelText: 'Power (CV)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Field required': null,
                ),
                TextFormField(
                  controller: _cylindresController,
                  decoration: const InputDecoration(labelText: 'Cylinders'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Field required' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCarburant,
                  decoration: const InputDecoration(labelText: 'Fuel (Carburant)'),
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
                  decoration: const InputDecoration(labelText: 'Kilometrage'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Field required' : null,
                ),
                TextFormField(
                  controller: _prixController,
                  decoration: const InputDecoration(labelText: 'Price (TND)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Field required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Ex: Good condition, first owner...',
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateVoiture,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}