import 'package:flutter/material.dart';
import '../models/voiture.dart';
import '../services/rendezvous_service.dart';
import '../database/database_helper.dart';

class RendezVousCreateScreen extends StatefulWidget {
  final Voiture voiture;

  const RendezVousCreateScreen({super.key, required this.voiture});

  @override
  State<RendezVousCreateScreen> createState() => _RendezVousCreateScreenState();
}

class _RendezVousCreateScreenState extends State<RendezVousCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final RendezVousService _service = RendezVousService();

  @override
  void dispose() {
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _heureController.text = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner la date et l\'heure')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Ensure DB is initialized for desktop
      DatabaseHelper.initializeFfi();

      final dateFormatted = _selectedDate != null
          ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
          : _dateController.text;

      final timeStr = _selectedTime!.hour.toString().padLeft(2, '0') + ':' + _selectedTime!.minute.toString().padLeft(2, '0');

      final created = await _service.creerRendezVous(
        matriculeVoiture: widget.voiture.matricule,
        dateRendezVous: dateFormatted,
        heureRendezVous: timeStr,
        lieu: _lieuController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rendez-vous créé'),
          content: Text('Rendez-vous créé pour ${widget.voiture.marque} ${widget.voiture.modele} le ${dateFormatted} à ${timeStr}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating rendez-vous: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planifier un Rendez-vous'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Véhicule sélectionné', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.blue[600], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${widget.voiture.marque} ${widget.voiture.modele}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Matricule: ${widget.voiture.matricule}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                  Text('Prix: ${widget.voiture.prixFormate}', style: TextStyle(fontSize: 16, color: Colors.green[700], fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text('Détails du rendez-vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 16),

                // Date
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date du rendez-vous *',
                    hintText: 'Sélectionnez une date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDate),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez sélectionner une date';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Heure
                TextFormField(
                  controller: _heureController,
                  decoration: InputDecoration(
                    labelText: 'Heure du rendez-vous *',
                    hintText: 'Sélectionnez une heure',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(icon: const Icon(Icons.schedule), onPressed: _pickTime),
                  ),
                  readOnly: true,
                  onTap: _pickTime,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez sélectionner une heure';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Lieu
                TextFormField(
                  controller: _lieuController,
                  decoration: InputDecoration(
                    labelText: 'Lieu du rendez-vous *',
                    hintText: 'Ex: Garage ABC, 123 Rue de la Paix, Paris',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez saisir le lieu du rendez-vous';
                    if (value.length < 5) return 'Le lieu doit contenir au moins 5 caractères';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optionnel)',
                    hintText: 'Ajoutez des informations supplémentaires...',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),

                const SizedBox(height: 32),

                // Bouton de validation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Planifier le Rendez-vous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Votre rendez-vous sera créé avec le statut "En attente". Vous pourrez le modifier depuis la liste des rendez-vous.', style: TextStyle(fontSize: 12, color: Colors.blue[800]))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
