import 'dart:convert';

class ShowroomEvent {
  final int? id;
  final String showroomId;
  final String title;
  final String? description;
  final DateTime date;
  final String eventType; // 'car_launch', 'test_drive', 'sales_event', 'maintenance_workshop', 'general'
  final String? location;
  final int? capacity;
  final List<String> imageGallery;
  final int attendeeCount; // Will be populated from queries

  ShowroomEvent({
    this.id,
    required this.showroomId,
    required this.title,
    this.description,
    required this.date,
    this.eventType = 'general',
    this.location,
    this.capacity,
    List<String>? imageGallery,
    this.attendeeCount = 0,
  }) : imageGallery = imageGallery ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'showroom_id': showroomId,
        'title': title,
        'description': description,
        'date': date.millisecondsSinceEpoch,
        'event_type': eventType,
        'location': location,
        'capacity': capacity,
        'image_gallery': imageGallery.isEmpty ? null : jsonEncode(imageGallery),
      };

  factory ShowroomEvent.fromMap(Map<String, dynamic> m) => ShowroomEvent(
        id: m['id'] as int?,
        showroomId: m['showroom_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        eventType: m['event_type'] as String? ?? 'general',
        location: m['location'] as String?,
        capacity: m['capacity'] as int?,
        imageGallery: m['image_gallery'] != null 
            ? List<String>.from(jsonDecode(m['image_gallery'] as String))
            : [],
        attendeeCount: m['attendee_count'] as int? ?? 0,
      );

  ShowroomEvent copyWith({
    int? id,
    String? showroomId,
    String? title,
    String? description,
    DateTime? date,
    String? eventType,
    String? location,
    int? capacity,
    List<String>? imageGallery,
    int? attendeeCount,
  }) {
    return ShowroomEvent(
      id: id ?? this.id,
      showroomId: showroomId ?? this.showroomId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      eventType: eventType ?? this.eventType,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      imageGallery: imageGallery ?? this.imageGallery,
      attendeeCount: attendeeCount ?? this.attendeeCount,
    );
  }

  String get eventTypeLabel {
    switch (eventType) {
      case 'car_launch':
        return 'Car Launch';
      case 'test_drive':
        return 'Test Drive';
      case 'sales_event':
        return 'Sales Event';
      case 'maintenance_workshop':
        return 'Maintenance Workshop';
      default:
        return 'General Event';
    }
  }

  bool get isFull => capacity != null && attendeeCount >= capacity!;
  bool get hasCapacity => capacity != null;
}

