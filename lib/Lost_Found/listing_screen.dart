import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'edit_item_screen.dart';
import 'lost_found_item.dart';
import 'lost_found_service.dart';
import 'post_item_screen.dart';
import 'secret_key_prompt.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final _service = LostFoundService();
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  String _searchText = '';

  Future<void> _contactOnWhatsapp(LostFoundItem item) async {
    final message = Uri.encodeComponent(
      'Hi! I saw your post about "${item.title}" on the LGU Connect Lost & Found.',
    );
    final number = item.whatsappNumber.replaceAll('+', '');
    final url = Uri.parse('https://wa.me/$number?text=$message');
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp. Is it installed?')),
      );
    }
  }

  Future<String?> _promptAndVerify(String title, LostFoundItem item) async {
    String? errorText;
    while (true) {
      final key = await promptForSecretKey(context, title: title, errorText: errorText);
      if (key == null) return null; // cancelled
      if (key.isEmpty) {
        errorText = 'Please enter the code.';
        continue;
      }
      final ok = await _service.verifySecretKey(item.id, key);
      if (!mounted) return null;
      if (!ok) {
        errorText = "That code doesn't match this listing.";
        continue;
      }
      return key;
    }
  }

  Future<void> _handleEdit(BuildContext sheetContext, LostFoundItem item) async {
    final key = await _promptAndVerify('Enter your secret code to edit', item);
    if (key == null || !mounted) return;

    Navigator.of(sheetContext).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditItemScreen(item: item, secretKey: key),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext sheetContext, LostFoundItem item) async {
    final key = await _promptAndVerify('Enter your secret code to delete', item);
    if (key == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this listing?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteItem(item.id, key);
      if (!mounted) return;
      Navigator.of(sheetContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  void _showItemDetail(LostFoundItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final sheetBg = isDark ? const Color(0xFF021E16) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: highlight.withValues(alpha: isDark ? 0.2 : 0.35),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    if (item.imageUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.imageUrls.first,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                            cacheWidth: 1000, // Optimized decoding size
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 240,
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              child: Icon(Icons.broken_image_outlined,
                                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                                  size: 40),
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: item.type == 'lost'
                                      ? Colors.red.withValues(alpha: isDark ? 0.22 : 0.14)
                                      : Colors.green.withValues(alpha: isDark ? 0.22 : 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.type.toUpperCase(),
                                  style: TextStyle(
                                    color: item.type == 'lost'
                                        ? (isDark ? Colors.red.shade200 : Colors.red.shade700)
                                        : (isDark ? Colors.greenAccent.shade100 : Colors.green.shade800),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: subTextColor),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.description,
                              style: TextStyle(color: subTextColor, height: 1.4),
                            ),
                          ),

                          const SizedBox(height: 16),

                          _infoRow(context, Icons.location_on, "Location", item.location),
                          const SizedBox(height: 10),
                          _infoRow(context, Icons.calendar_today, "Date",
                              DateFormat.yMMMd().format(item.date)),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _contactOnWhatsapp(item),
                              icon: const Icon(Icons.chat),
                              label: const Text(
                                'Contact via WhatsApp',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: BorderSide(color: highlight.withValues(alpha: 0.7)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _handleEdit(sheetContext, item),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.red.shade200 : Colors.red.shade700,
                                    side: BorderSide(
                                      color: (isDark ? Colors.red.shade200 : Colors.red.shade700)
                                          .withValues(alpha: 0.7),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _handleDelete(sheetContext, item),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (context, i) {
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.square(size: 80, borderRadius: BorderRadius.circular(12)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LOST',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sample item title goes here',
                          maxLines: 1,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category, size: 14,
                                color: isDark ? Colors.white38 : Colors.grey.shade600),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text('Category', maxLines: 1, style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14,
                                color: isDark ? Colors.white38 : Colors.grey.shade600),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text('Location text', maxLines: 1, style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16,
                      color: isDark ? Colors.white38 : Colors.grey.shade600),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? highlight.withValues(alpha: 0.2) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? highlight : Colors.grey.shade800),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final cardColor = isDark ? const Color(0xFF0B3D2E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: highlight,
        foregroundColor: isDark ? Colors.black : Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PostItemScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Report item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by title',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white60 : Colors.grey.shade700),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? highlight.withValues(alpha: 0.25)
                        : highlight.withValues(alpha: 0.45),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? highlight.withValues(alpha: 0.25)
                        : highlight.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: highlight, width: 1.5),
                ),
              ),
              onChanged: (v) =>
                  setState(() => _searchText = v.trim().toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildChip('All', _typeFilter == 'all', () => setState(() => _typeFilter = 'all'), isDark, highlight),
                const SizedBox(width: 8),
                _buildChip('Lost', _typeFilter == 'lost', () => setState(() => _typeFilter = 'lost'), isDark, highlight),
                const SizedBox(width: 8),
                _buildChip('Found', _typeFilter == 'found', () => setState(() => _typeFilter = 'found'), isDark, highlight),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? highlight.withValues(alpha: 0.25)
                          : highlight.withValues(alpha: 0.45),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _categoryFilter,
                      dropdownColor: cardColor,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black54),
                      items: ['all', ...lostFoundCategories]
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c == 'all' ? 'All categories' : c),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _categoryFilter = v ?? 'all'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<LostFoundItem>>(
              stream: _service.getItems(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return _buildSkeletonList(context);
                }
                var items = snapshot.data!;
                // Only show active items to regular users
                items = items.where((i) => i.status == 'active').toList();

                items = items.where((i) {
                  final matchesType = _typeFilter == 'all' || i.type == _typeFilter;
                  final matchesCategory =
                      _categoryFilter == 'all' || i.category == _categoryFilter;
                  final matchesSearch = _searchText.isEmpty ||
                      i.title.toLowerCase().contains(_searchText);
                  return matchesType && matchesCategory && matchesSearch;
                }).toList();
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No items match your filters yet.',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showItemDetail(item),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item.imageUrls.isNotEmpty
                                    ? Image.network(
                                  item.imageUrls.first,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  cacheWidth: 240, // Optimization: only decode at thumbnail size
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 80,
                                    height: 80,
                                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                                    child: Icon(Icons.broken_image_outlined,
                                        color: isDark ? Colors.white30 : Colors.grey.shade400),
                                  ),
                                )
                                    : Container(
                                  width: 80,
                                  height: 80,
                                  color: highlight.withValues(alpha: isDark ? 0.12 : 0.1),
                                  child: Center(
                                    child: Text(
                                      item.category.isNotEmpty
                                          ? item.category[0]
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: highlight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.type == 'lost'
                                            ? Colors.red.withValues(alpha: isDark ? 0.22 : 0.14)
                                            : Colors.green.withValues(alpha: isDark ? 0.22 : 0.14),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        item.type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: item.type == 'lost'
                                              ? (isDark ? Colors.red.shade200 : Colors.red.shade700)
                                              : (isDark ? Colors.greenAccent.shade100 : Colors.green.shade800),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        Icon(Icons.category,
                                            size: 14,
                                            color: isDark ? Colors.white54 : Colors.grey.shade700),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.category,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : Colors.grey.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 2),

                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 14,
                                            color: isDark ? Colors.white54 : Colors.grey.shade700),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white54 : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isDark ? Colors.white38 : Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap, bool isDark, Color highlight) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: isDark ? const Color(0xFF0B3D2E) : Colors.white,
      selectedColor: highlight,
      labelStyle: TextStyle(
        color: selected
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? Colors.transparent : highlight.withValues(alpha: isDark ? 0.25 : 0.45),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
