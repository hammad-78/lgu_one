import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UpcomingEventsScreen extends StatefulWidget {
  const UpcomingEventsScreen({super.key});

  @override
  State<UpcomingEventsScreen> createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  final CollectionReference _eventsRef =
      FirebaseFirestore.instance.collection('events');

  String _selectedCategory = 'All'; // 'All', 'Within University', 'Within Lahore'
  DateTime? _selectedDateFilter;



  String _formatFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return "Today, ${DateFormat('h:mm a').format(date)}";
    } else if (difference == 1) {
      return "Tomorrow, ${DateFormat('h:mm a').format(date)}";
    } else if (difference > 1 && difference <= 7) {
      return "In $difference days (${DateFormat('EEE, h:mm a').format(date)})";
    } else {
      return DateFormat('EEE, dd MMM yyyy • h:mm a').format(date);
    }
  }

  String _getCountdownText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final diff = targetDate.difference(today).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Tomorrow";
    if (diff > 1) return "In $diff days";
    return "${diff.abs()} days ago";
  }

  void _showEventDetail(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String title = data['title'] ?? 'Event Detail';
    final String description = data['description'] ?? 'No description provided.';
    final String categoryRaw = data['category'] ?? 'University';
    final String categoryDisplay =
        categoryRaw == 'Lahore' ? 'Within Lahore' : 'Within University';
    final String location = data['location'] ?? 'Location not specified';
    final String? imageUrl = data['imageUrl'] as String?;

    DateTime? eventDate;
    if (data['eventDate'] != null && data['eventDate'] is Timestamp) {
      eventDate = (data['eventDate'] as Timestamp).toDate();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0B3D2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported,
                              size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryRaw == 'Lahore'
                          ? (isDark
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.15))
                          : (isDark
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      categoryDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: categoryRaw == 'Lahore'
                            ? (isDark
                                ? const Color(0xFFD4AF37)
                                : Colors.orange.shade800)
                            : (isDark ? Colors.lightGreenAccent : Colors.green.shade800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date info row
                  if (eventDate != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, dd MMMM yyyy • h:mm a')
                                .format(eventDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Location info row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: isDark
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  Text(
                    "About Event",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF4CAF50),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Events"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsRef
            .where('eventDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .orderBy('eventDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Error loading events: ${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonLoader(isDark);
          }

          final docs = snapshot.data?.docs ?? [];

          // Client-side category filtering
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = data['category'] ?? 'University';
            if (_selectedCategory == 'Within University') {
              return cat == 'University';
            }
            if (_selectedCategory == 'Within Lahore') {
              return cat == 'Lahore';
            }
            return true;
          }).where((doc) {
            if (_selectedDateFilter == null) return true;
            final data = doc.data() as Map<String, dynamic>;
            if (data['eventDate'] is Timestamp) {
              final date = (data['eventDate'] as Timestamp).toDate();
              return date.year == _selectedDateFilter!.year &&
                  date.month == _selectedDateFilter!.month &&
                  date.day == _selectedDateFilter!.day;
            }
            return true;
          }).toList();

          // Extract unique upcoming dates for date strip rail
          final List<DateTime> uniqueDates = [];
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['eventDate'] is Timestamp) {
              final date = (data['eventDate'] as Timestamp).toDate();
              final dayDate = DateTime(date.year, date.month, date.day);
              if (!uniqueDates.contains(dayDate)) {
                uniqueDates.add(dayDate);
              }
            }
          }

          return Column(
            children: [
              // Category Filter Selector
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'All',
                      label: Text("All"),
                    ),
                    ButtonSegment(
                      value: 'Within University',
                      label: Text("University"),
                      icon: Icon(Icons.school_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'Within Lahore',
                      label: Text("Lahore"),
                      icon: Icon(Icons.location_city_outlined, size: 16),
                    ),
                  ],
                  selected: {_selectedCategory},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedCategory = selection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: isDark
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF4CAF50),
                    selectedForegroundColor:
                        isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),

              // Calendar Date Strip Rail
              if (uniqueDates.isNotEmpty)
                Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: uniqueDates.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedDateFilter == null;
                        return ChoiceChip(
                          label: const Text("All Dates"),
                          selected: isSelected,
                          selectedColor: isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFF4CAF50),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedDateFilter = null);
                          },
                        );
                      }

                      final date = uniqueDates[index - 1];
                      final isSelected = _selectedDateFilter != null &&
                          _selectedDateFilter!.year == date.year &&
                          _selectedDateFilter!.month == date.month &&
                          _selectedDateFilter!.day == date.day;

                      final dayStr = DateFormat('dd').format(date);
                      final monthStr = DateFormat('MMM').format(date).toUpperCase();

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDateFilter = null;
                            } else {
                              _selectedDateFilter = date;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 55,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFFD4AF37)
                                    : const Color(0xFF4CAF50))
                                : (isDark
                                    ? const Color(0xFF0B3D2E)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFFD4AF37)
                                      : const Color(0xFF4CAF50))
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.grey.shade300),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayStr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              Text(
                                monthStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? (isDark
                                          ? Colors.black87
                                          : Colors.white70)
                                      : (isDark
                                          ? const Color(0xFFD4AF37)
                                          : const Color(0xFF4CAF50)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 6),

              // Events List
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 54,
                              color: isDark
                                  ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                                  : const Color(0xFF4CAF50).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "No upcoming events right now",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Check back soon for new campus announcements!",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildEventCard(context, data, isDark);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
      BuildContext context, Map<String, dynamic> data, bool isDark) {
    final String title = data['title'] ?? 'Untitled Event';
    final String categoryRaw = data['category'] ?? 'University';
    final String categoryDisplay =
        categoryRaw == 'Lahore' ? 'Within Lahore' : 'Within University';
    final String location = data['location'] ?? '';
    final String? imageUrl = data['imageUrl'] as String?;

    DateTime? eventDate;
    if (data['eventDate'] != null && data['eventDate'] is Timestamp) {
      eventDate = (data['eventDate'] as Timestamp).toDate();
    }

    final countdownStr =
        eventDate != null ? _getCountdownText(eventDate) : 'Upcoming';
    final dateStr =
        eventDate != null ? _formatFriendlyDate(eventDate) : 'Date TBD';

    return GestureDetector(
      onTap: () => _showEventDetail(context, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B3D2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                : const Color(0xFF4CAF50).withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: categoryRaw == 'Lahore'
                              ? (isDark
                                  ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.15))
                              : (isDark
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categoryDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: categoryRaw == 'Lahore'
                                ? (isDark
                                    ? const Color(0xFFD4AF37)
                                    : Colors.orange.shade800)
                                : (isDark
                                    ? Colors.lightGreenAccent
                                    : Colors.green.shade800),
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Countdown badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          countdownStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 15,
                        color: isDark
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Location row
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B3D2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}


