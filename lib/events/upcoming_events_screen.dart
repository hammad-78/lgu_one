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

  String _selectedCategory = 'All'; 
  DateTime? _startDate;
  DateTime? _endDate;

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

  bool _isSpecificDate(DateTime date) {
    if (_startDate == null || _endDate == null) return false;
    if (_startDate != _endDate) return false;
    return _startDate!.year == date.year && _startDate!.month == date.month && _startDate!.day == date.day;
  }

  void _setSpecificDate(DateTime date) {
    setState(() {
      _startDate = DateTime(date.year, date.month, date.day);
      _endDate = _startDate;
    });
  }

  Future<void> _selectSingleDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50),
                  onPrimary: isDark ? Colors.black : Colors.white,
                  surface: isDark ? const Color(0xFF0B3D2E) : Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) _setSpecificDate(picked);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _startDate != null && _endDate != null && _startDate != _endDate
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50),
                  onPrimary: isDark ? Colors.black : Colors.white,
                  surface: isDark ? const Color(0xFF0B3D2E) : Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
    }
  }

  void _showEventDetail(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String title = data['title'] ?? 'Event Detail';
    final String description = data['description'] ?? 'No description provided.';
    final String categoryRaw = data['category'] ?? 'University';
    final String categoryDisplay = categoryRaw == 'Lahore' ? 'Within Lahore' : 'Within University';
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75, minChildSize: 0.4, maxChildSize: 0.92, expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey))),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: categoryRaw == 'Lahore' ? (isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.15)) : (isDark ? const Color(0xFF4CAF50).withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.15)), borderRadius: BorderRadius.circular(20)),
                    child: Text(categoryDisplay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: categoryRaw == 'Lahore' ? (isDark ? const Color(0xFFD4AF37) : Colors.orange.shade800) : (isDark ? Colors.lightGreenAccent : Colors.green.shade800))),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 14),
                  if (eventDate != null) ...[
                    Row(children: [Icon(Icons.calendar_today, size: 18, color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50)), const SizedBox(width: 10), Expanded(child: Text(DateFormat('EEEE, dd MMMM yyyy • h:mm a').format(eventDate), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)))]),
                    const SizedBox(height: 10),
                  ],
                  Row(children: [Icon(Icons.location_on, size: 18, color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50)), const SizedBox(width: 10), Expanded(child: Text(location, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)))]),
                  const Divider(height: 30),
                  Text("About Event", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50), foregroundColor: isDark ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
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
      appBar: AppBar(title: const Text("Upcoming Events"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsRef
            .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .orderBy('eventDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text("Error loading events: ${snapshot.error}")));
          if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonLoader(isDark);

          final docs = snapshot.data?.docs ?? [];
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = data['category'] ?? 'University';
            if (_selectedCategory == 'Within University' && cat != 'University') return false;
            if (_selectedCategory == 'Within Lahore' && cat != 'Lahore') return false;
            if (_startDate != null && _endDate != null) {
              if (data['eventDate'] is Timestamp) {
                final date = (data['eventDate'] as Timestamp).toDate();
                final eventDay = DateTime(date.year, date.month, date.day);
                if (eventDay.isBefore(_startDate!) || eventDay.isAfter(_endDate!)) return false;
              }
            }
            return true;
          }).toList();

          return Column(
            children: [
              // 1. Category Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text("All Categories")),
                    ButtonSegment(value: 'Within University', label: Text("Campus"), icon: Icon(Icons.school, size: 16)),
                    ButtonSegment(value: 'Within Lahore', label: Text("Lahore"), icon: Icon(Icons.location_city, size: 16)),
                  ],
                  selected: {_selectedCategory},
                  onSelectionChanged: (selection) => setState(() => _selectedCategory = selection.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50),
                    selectedForegroundColor: isDark ? Colors.black : Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

              // 2. Date Filter Chips
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(label: "All Dates", isSelected: _startDate == null, onTap: () => setState(() { _startDate = null; _endDate = null; }), isDark: isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: "Today", isSelected: _isSpecificDate(startOfToday), onTap: () => _setSpecificDate(startOfToday), isDark: isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: "Tomorrow", isSelected: _isSpecificDate(startOfToday.add(const Duration(days: 1))), onTap: () => _setSpecificDate(startOfToday.add(const Duration(days: 1))), isDark: isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: "Pick a Date", icon: Icons.event, isSelected: _startDate != null && _startDate == _endDate && !_isSpecificDate(startOfToday) && !_isSpecificDate(startOfToday.add(const Duration(days: 1))), onTap: _selectSingleDate, isDark: isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: "Timeline", icon: Icons.date_range, isSelected: _startDate != null && _startDate != _endDate, onTap: _selectDateRange, isDark: isDark),
                  ],
                ),
              ),

              // Active Filter Indicator
              if (_startDate != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.3) : const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 14, color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _startDate == _endDate 
                            ? "Events on ${DateFormat('dd MMM yyyy').format(_startDate!)}"
                            : "Events from ${DateFormat('dd MMM').format(_startDate!)} to ${DateFormat('dd MMM yyyy').format(_endDate!)}",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() { _startDate = null; _endDate = null; }),
                        child: const Text("Reset", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 4),

              // 3. Events List
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text("No events found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(_startDate != null ? "Try clearing your date filters" : "Check back later for new events", style: TextStyle(color: Colors.grey.shade500)),
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

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap, IconData? icon, required bool isDark}) {
    final color = isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? (isDark ? Colors.black : Colors.white) : color) : null,
      selectedColor: color,
      backgroundColor: isDark ? const Color(0xFF0B3D2E) : Colors.white,
      checkmarkColor: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.shade300))),
      labelStyle: TextStyle(color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final String title = data['title'] ?? 'Untitled Event';
    final String categoryRaw = data['category'] ?? 'University';
    final String categoryDisplay = categoryRaw == 'Lahore' ? 'Within Lahore' : 'Within University';
    final String location = data['location'] ?? '';
    final String? imageUrl = data['imageUrl'] as String?;
    DateTime? eventDate;
    if (data['eventDate'] != null && data['eventDate'] is Timestamp) eventDate = (data['eventDate'] as Timestamp).toDate();
    final countdownStr = eventDate != null ? _getCountdownText(eventDate) : 'Upcoming';
    final dateStr = eventDate != null ? _formatFriendlyDate(eventDate) : 'Date TBD';

    return GestureDetector(
      onTap: () => _showEventDetail(context, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF0B3D2E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.25) : const Color(0xFF4CAF50).withValues(alpha: 0.2)), boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: categoryRaw == 'Lahore' ? (isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.15)) : (isDark ? const Color(0xFF4CAF50).withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.15)), borderRadius: BorderRadius.circular(20)),
                        child: Text(categoryDisplay, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: categoryRaw == 'Lahore' ? (isDark ? const Color(0xFFD4AF37) : Colors.orange.shade800) : (isDark ? Colors.lightGreenAccent : Colors.green.shade800))),
                      ),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(20)), child: Text(countdownStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.black : Colors.white))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Row(children: [Icon(Icons.access_time, size: 15, color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50)), const SizedBox(width: 6), Expanded(child: Text(dateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)))]),
                  if (location.isNotEmpty) ...[const SizedBox(height: 6), Row(children: [Icon(Icons.location_on_outlined, size: 15, color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50)), const SizedBox(width: 6), Expanded(child: Text(location, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis))])],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return Skeletonizer(enabled: true, child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (context, index) { return Container(margin: const EdgeInsets.only(bottom: 14), height: 180, decoration: BoxDecoration(color: isDark ? const Color(0xFF0B3D2E) : Colors.white, borderRadius: BorderRadius.circular(16))); }));
  }
}
