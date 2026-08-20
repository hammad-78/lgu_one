import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lgu_one/admin/add_edit_event_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final CollectionReference _eventsRef =
      FirebaseFirestore.instance.collection('events');

  String _categoryFilter = 'All'; // 'All', 'Within University', 'Within Lahore'
  final List<String> _filterOptions = [
    'All',
    'Within University',
    'Within Lahore'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Events"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditEventScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Event",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = _filterOptions[index];
                  final isSelected = _categoryFilter == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _categoryFilter = option);
                    },
                  );
                },
              ),
            ),
          ),

          // Events Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _eventsRef.orderBy('eventDate', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered = _categoryFilter == 'All'
                    ? docs
                    : docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final cat = (data['category'] ?? '').toString();
                        if (_categoryFilter == 'Within University') {
                          return cat == 'University';
                        }
                        if (_categoryFilter == 'Within Lahore') {
                          return cat == 'Lahore';
                        }
                        return true;
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.38)),
                        const SizedBox(height: 12),
                        Text(
                          "No events found",
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.54), fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildEventCard(context, doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String title = data['title'] ?? 'Untitled Event';
    final String description = data['description'] ?? '';
    final String categoryRaw = data['category'] ?? 'University';
    final String categoryDisplay =
        categoryRaw == 'Lahore' ? 'Within Lahore' : 'Within University';
    final String location = data['location'] ?? '';
    final String? imageUrl = data['imageUrl'] as String?;

    DateTime? eventDate;
    if (data['eventDate'] != null && data['eventDate'] is Timestamp) {
      eventDate = (data['eventDate'] as Timestamp).toDate();
    }

    final bool isPast =
        eventDate != null && eventDate.isBefore(DateTime.now());

    final formattedDate = eventDate != null
        ? DateFormat('EEE, dd MMM yyyy - hh:mm a').format(eventDate)
        : 'No date set';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPast ? (isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50) : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPast
              ? (isDark ? Colors.white10 : Colors.grey.shade300)
              : (isDark ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.2)),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(isPast ? 0.04 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: isPast
                          ? (isDark ? Colors.white10 : Colors.grey.shade200)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.event,
                        color: isPast ? Colors.grey : theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isPast ? theme.colorScheme.onSurface.withOpacity(0.54) : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Status Badge (Upcoming vs Past)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPast
                              ? (isDark ? Colors.white24 : Colors.grey.shade400)
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPast ? 'PAST' : 'UPCOMING',
                          style: TextStyle(
                            color: isPast ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: categoryRaw == 'Lahore'
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      categoryDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: categoryRaw == 'Lahore'
                            ? (isDark ? Colors.orangeAccent : Colors.orange.shade800)
                            : (isDark ? Colors.blueAccent : Colors.blue.shade800),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Date & Time
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 13, color: theme.colorScheme.onSurface.withOpacity(0.54)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                              fontSize: 12, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: theme.colorScheme.onSurface.withOpacity(0.54)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                                fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.54)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPast ? theme.colorScheme.onSurface.withOpacity(0.38) : theme.colorScheme.onSurface.withOpacity(0.54),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Action Buttons
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditEventScreen(
                                eventId: docId,
                                eventData: data,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Edit"),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(docId),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text("Delete"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Event"),
          content: const Text(
              "Are you sure you want to delete this event? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteEvent(docId);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent(String docId) async {
    try {
      await _eventsRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event deleted successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
  }
}
