import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_edit_society_screen.dart';

class AdminSocietiesScreen extends StatelessWidget {
  const AdminSocietiesScreen({super.key});

  Future<void> _deleteSociety(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete society?'),
        content: const Text('This society will be removed from the student app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('societies').doc(id).delete();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete society: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final societies = FirebaseFirestore.instance
        .collection('societies')
        .orderBy('name')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Societies')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditSocietyScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Society'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: societies,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No societies found'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.groups)),
                  title: Text((data['name'] ?? 'Untitled Society').toString()),
                  subtitle: Text((data['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditSocietyScreen(
                              societyId: doc.id,
                              societyData: data,
                            ),
                          ),
                        );
                      } else {
                        _deleteSociety(context, doc.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}