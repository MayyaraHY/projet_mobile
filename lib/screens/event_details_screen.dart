import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/event_attendee.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../widgets/avatar_generator.dart';

class EventDetailsScreen extends StatefulWidget {
  final int eventId;

  const EventDetailsScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _eventService = EventService();
  ShowroomEvent? _event;
  List<EventAttendee> _attendees = [];
  Map<String, int> _stats = {};
  bool _loading = true;
  bool _isRegistered = false;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    setState(() => _loading = true);

    final auth = context.read<AuthService>();
    final uid = auth.currentUid;

    final event = await _eventService.getEventById(widget.eventId);
    final attendees = await _eventService.getEventAttendees(widget.eventId, status: 'registered');
    final stats = await _eventService.getEventStats(widget.eventId);
    
    bool registered = false;
    if (uid != null) {
      registered = await _eventService.isUserRegistered(widget.eventId, uid);
    }

    setState(() {
      _event = event;
      _attendees = attendees;
      _stats = stats;
      _isRegistered = registered;
      _loading = false;
    });
  }

  Future<void> _handleRSVP() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to register for events'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _actionLoading = true);

    try {
      bool success;
      if (_isRegistered) {
        success = await _eventService.cancelRegistration(widget.eventId, uid);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        success = await _eventService.registerForEvent(widget.eventId, uid);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully registered! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event is full or you are already registered'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (success) {
        await _loadEventDetails();
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
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final event = _event!;
    final isPastEvent = event.date.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Type Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.eventTypeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy • HH:mm').format(event.date),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          event.location!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Capacity Info
                  if (event.hasCapacity) ...[
                    Card(
                      color: event.isFull ? Colors.red.shade50 : Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              event.isFull ? Icons.event_busy : Icons.event_available,
                              color: event.isFull ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.isFull ? 'Event Full' : 'Spots Available',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: event.isFull ? Colors.red.shade700 : Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${event.attendeeCount} / ${event.capacity} attendees',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${((event.attendeeCount / event.capacity!) * 100).round()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: event.isFull ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Statistics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                '✅ Registered',
                                _stats['registered']?.toString() ?? '0',
                                Colors.green,
                              ),
                              _buildStatItem(
                                '👥 Attended',
                                _stats['attended']?.toString() ?? '0',
                                Colors.blue,
                              ),
                              _buildStatItem(
                                '❌ Cancelled',
                                _stats['cancelled']?.toString() ?? '0',
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Attendees List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registered Attendees',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_attendees.length} people',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_attendees.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'No one registered yet',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to register!',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_attendees.take(10).map((attendee) => Card(
                          child: ListTile(
                            leading: attendee.userPhoto != null
                                ? CircleAvatar(
                                    backgroundImage: FileImage(File(attendee.userPhoto!)),
                                  )
                                : AvatarGenerator.generateAvatar(
                                    seed: attendee.userId,
                                    size: 40,
                                    emoji: attendee.userAvatarEmoji,
                                    color: attendee.userAvatarColor,
                                  ),
                            title: Text(attendee.userName ?? 'User'),
                            subtitle: Text(
                              DateFormat('MMM dd, yyyy').format(attendee.registeredAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Icon(
                              Icons.check_circle,
                              color: Colors.green.shade400,
                              size: 20,
                            ),
                          ),
                        ))),

                  if (_attendees.length > 10)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          '+ ${_attendees.length - 10} more attendees',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isPastEvent
          ? null
          : FloatingActionButton.extended(
              onPressed: _actionLoading || (event.isFull && !_isRegistered)
                  ? null
                  : _handleRSVP,
              icon: _actionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(_isRegistered ? Icons.cancel : Icons.check_circle),
              label: Text(
                _isRegistered
                    ? 'Cancel Registration'
                    : event.isFull
                        ? 'Event Full'
                        : 'Register Now',
              ),
              backgroundColor: _isRegistered
                  ? Colors.orange
                  : event.isFull
                      ? Colors.grey
                      : Colors.green,
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
