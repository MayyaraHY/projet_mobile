import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventFormScreen extends StatefulWidget {
  final String showroomId;
  final ShowroomEvent? event; // null for new event, existing event for edit

  const EventFormScreen({
    Key? key,
    required this.showroomId,
    this.event,
  }) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedType = 'general';
  bool _hasCapacity = false;
  bool _loading = false;

  final List<Map<String, String>> _eventTypes = [
    {'value': 'general', 'label': 'General Event', 'icon': '📅'},
    {'value': 'car_launch', 'label': 'Car Launch', 'icon': '🚗'},
    {'value': 'test_drive', 'label': 'Test Drive', 'icon': '🏁'},
    {'value': 'sales_event', 'label': 'Sales Event', 'icon': '💰'},
    {'value': 'maintenance_workshop', 'label': 'Maintenance Workshop', 'icon': '🔧'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleCtrl.text = widget.event!.title;
      _descriptionCtrl.text = widget.event!.description ?? '';
      _locationCtrl.text = widget.event!.location ?? '';
      _selectedDate = widget.event!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.date);
      _selectedType = widget.event!.eventType;
      _hasCapacity = widget.event!.capacity != null;
      if (_hasCapacity) {
        _capacityCtrl.text = widget.event!.capacity.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final event = ShowroomEvent(
      id: widget.event?.id,
      showroomId: widget.showroomId,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      date: _combinedDateTime,
      eventType: _selectedType,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      capacity: _hasCapacity && _capacityCtrl.text.isNotEmpty 
          ? int.tryParse(_capacityCtrl.text) 
          : null,
    );

    try {
      final service = EventService();
      if (widget.event == null) {
        await service.addEvent(event);
      } else {
        await service.updateEvent(event);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event == null ? 'Event created!' : 'Event updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Event' : 'Create Event'),
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEvent,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Event Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _eventTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(type['icon']!),
                              const SizedBox(width: 4),
                              Text(type['label']!),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type['value']!);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Event Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      onTap: _selectDate,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      onTap: _selectTime,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'e.g., Main Showroom, Branch 2',
              ),
            ),
            const SizedBox(height: 16),

            // Capacity Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Set Capacity Limit'),
                subtitle: Text(_hasCapacity 
                    ? 'Limited attendance' 
                    : 'Unlimited attendance'),
                value: _hasCapacity,
                onChanged: (val) {
                  setState(() => _hasCapacity = val);
                  if (!val) _capacityCtrl.clear();
                },
              ),
            ),
            
            // Capacity Input
            if (_hasCapacity) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Maximum Attendees *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                  hintText: 'e.g., 50',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (!_hasCapacity) return null;
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  final num = int.tryParse(v!);
                  if (num == null || num <= 0) return 'Enter valid number';
                  return null;
                },
              ),
            ],
            
            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Event Preview',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📅 ${DateFormat('EEEE, MMM dd, yyyy').format(_combinedDateTime)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '🕐 ${_selectedTime.format(context)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_locationCtrl.text.isNotEmpty)
                      Text(
                        '📍 ${_locationCtrl.text}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (_hasCapacity && _capacityCtrl.text.isNotEmpty)
                      Text(
                        '👥 Max ${_capacityCtrl.text} attendees',
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
