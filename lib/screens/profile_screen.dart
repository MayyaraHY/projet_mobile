import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import '../services/event_service.dart';
import '../services/session_service.dart';
import '../models/event.dart';
import '../widgets/avatar_generator.dart';
import 'avatar_picker_screen.dart';
import 'event_form_screen.dart';
import 'event_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  bool _loading = false;
  List<ShowroomEvent> _events = [];
  bool _eventsLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // events will be loaded when the screen builds and we have auth
  }

  Future<void> _loadEvents(String showroomId) async {
    setState(() => _eventsLoading = true);
    _events = await EventService().getEventsForShowroom(showroomId);
    setState(() => _eventsLoading = false);
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'car_launch':
        return Icons.directions_car;
      case 'test_drive':
        return Icons.speed;
      case 'sales_event':
        return Icons.local_offer;
      case 'maintenance_workshop':
        return Icons.build;
      default:
        return Icons.event;
    }
  }

  Future<void> _showDeviceSessions(BuildContext context, AuthService auth) async {
    final uid = auth.currentUid;
    if (uid == null) return;

    final sessions = await SessionService().getUserSessions(uid);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Sessions'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sessions.isEmpty)
                const Text('No active sessions')
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          session.deviceType.toLowerCase().contains('android') ? Icons.phone_android :
                          session.deviceType.toLowerCase().contains('ios') ? Icons.phone_iphone :
                          Icons.computer,
                        ),
                        title: Text(session.deviceName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last active: ${session.getTimeAgo()}'),
                            Text('Created: ${session.createdAt.toString().split('.')[0]}'),
                          ],
                        ),
                        trailing: session.isCurrent
                            ? const Chip(label: Text('Current'), backgroundColor: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await SessionService().deleteSession(session.sessionId);
                                  Navigator.pop(context);
                                  _showDeviceSessions(context, auth);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Session removed')),
                                    );
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final currentSession = SessionService().currentSessionId;
                  if (currentSession != null) {
                    await SessionService().deleteAllOtherSessions(uid, currentSession);
                    Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All other sessions logged out')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout All Other Devices'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final auth = Provider.of<AuthService>(context);
  final displayName = auth.currentDisplayName;
  final email = auth.currentEmail;
  final uid = auth.currentUid;
  _displayNameCtrl.text = displayName ?? '';

  // load events for showroom once
  if ((auth.currentUser?.roles.isShowroom ?? false) && uid != null && !_eventsLoading && _events.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvents(uid));
  }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await auth.signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _openAvatarPicker(context, auth),
              child: Stack(
                children: [
                  if (auth.currentPhotoPath != null)
                    CircleAvatar(radius: 48, backgroundImage: FileImage(File(auth.currentPhotoPath!)))
                  else if (auth.currentAvatarEmoji != null && auth.currentAvatarColor != null)
                    _buildCustomAvatar(auth.currentAvatarEmoji!, auth.currentAvatarColor!)
                  else
                    AvatarGenerator.generateAvatar(
                      seed: email ?? displayName ?? 'User',
                      size: 96,
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(email ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            // Seller score
            if (uid != null)
              FutureBuilder<double>(
                future: RatingService().getAverageRating(uid),
                builder: (context, snapshot) {
                  final score = snapshot.data ?? 0.0;
                  return Text('Score vendeur: ${score.toStringAsFixed(1)} / 5', style: const TextStyle(fontSize: 16));
                },
              ),
            const SizedBox(height: 16),
            TextField(controller: _displayNameCtrl, decoration: const InputDecoration(labelText: 'Nom affiché')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                  setState(() => _loading = true);
                  final err = await auth.updateDisplayName(_displayNameCtrl.text.trim());
                  setState(() => _loading = false);
                  if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              },
              child: _loading ? const CircularProgressIndicator() : const Text('Mettre à jour le nom'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                  setState(() => _loading = true);
                  final err = await auth.updateProfilePictureFromImagePicker();
                  setState(() => _loading = false);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  }
              },
              child: const Text('Changer la photo'),
            ),
            const Divider(height: 24),
            // Showroom events
            if (auth.currentUser?.roles.isShowroom ?? false) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Showroom Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (auth.currentUid == null) return;
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventFormScreen(showroomId: auth.currentUid!),
                        ),
                      );
                      if (result == true && auth.currentUid != null) {
                        _loadEvents(auth.currentUid!);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _eventsLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : _events.isEmpty 
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No events yet',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create your first event!',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _events.map((event) {
                            final isPast = event.date.isBefore(DateTime.now());
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPast ? Colors.grey.shade300 : Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getEventIcon(event.eventType),
                                    color: isPast ? Colors.grey : Theme.of(context).primaryColor,
                                  ),
                                ),
                                title: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPast ? Colors.grey : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.eventTypeLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPast ? Colors.grey : Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM dd, yyyy • HH:mm').format(event.date),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (event.hasCapacity)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            size: 14,
                                            color: event.isFull ? Colors.red : Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${event.attendeeCount}/${event.capacity}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: event.isFull ? Colors.red : Colors.green,
                                            ),
                                          ),
                                          if (event.isFull) ...[
                                            const SizedBox(width: 4),
                                            const Text(
                                              '(FULL)',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isPast) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () async {
                                          if (auth.currentUid == null) return;
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EventFormScreen(
                                                showroomId: auth.currentUid!,
                                                event: event,
                                              ),
                                            ),
                                          );
                                          if (result == true && auth.currentUid != null) {
                                            _loadEvents(auth.currentUid!);
                                          }
                                        },
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Event'),
                                              content: Text('Delete "${event.title}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true && event.id != null) {
                                            await EventService().deleteEvent(event.id!);
                                            if (auth.currentUid != null) {
                                              _loadEvents(auth.currentUid!);
                                            }
                                          }
                                        },
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: event.id != null
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EventDetailsScreen(eventId: event.id!),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
              const Divider(height: 24),
            ],
            TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Nouveau mot de passe'), obscureText: true),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                if (_passwordCtrl.text.isEmpty) return;
                setState(() => _loading = true);
                final err = await auth.updatePassword(_passwordCtrl.text);
                setState(() => _loading = false);
                if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour')));
              },
              child: _loading ? const CircularProgressIndicator() : const Text('Changer le mot de passe'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            // Device Sessions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showDeviceSessions(context, auth),
                  icon: const Icon(Icons.devices),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<DeviceSession>>(
              future: uid != null ? SessionService().getUserSessions(uid) : Future.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final sessions = snapshot.data ?? [];
                final activeSessions = sessions.where((s) => 
                  DateTime.now().difference(s.lastActiveAt).inDays < 7
                ).toList();
                
                if (activeSessions.isEmpty) {
                  return const Text('No active devices');
                }
                
                return Column(
                  children: activeSessions.take(2).map((session) {
                    return ListTile(
                      leading: Icon(
                        session.deviceType.toLowerCase().contains('android') ? Icons.phone_android :
                        session.deviceType.toLowerCase().contains('ios') ? Icons.phone_iphone :
                        Icons.computer,
                        color: session.isCurrent ? Colors.green : Colors.grey,
                      ),
                      title: Text(session.deviceName),
                      subtitle: Text(session.getTimeAgo()),
                      trailing: session.isCurrent ? 
                        const Chip(label: Text('Current', style: TextStyle(fontSize: 10)), 
                          backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white)) : null,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer le compte'),
                    content: const Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront supprimées.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  setState(() => _loading = true);
                  final err = await auth.deleteAccount();
                  setState(() => _loading = false);
                  
                  if (err != null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $err'), backgroundColor: Colors.red),
                    );
                  } else {
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer mon compte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAvatar(String emoji, int colorValue) {
    final color = Color(colorValue);
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Future<void> _openAvatarPicker(BuildContext context, AuthService auth) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AvatarPickerScreen()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      final emoji = result['emoji'] as String;
      final color = result['color'] as int;
      
      setState(() => _loading = true);
      final err = await auth.updateCustomAvatar(emoji, color);
      setState(() => _loading = false);
      
      if (err != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar mis à jour!')),
          );
        }
      }
    }
  }
}
