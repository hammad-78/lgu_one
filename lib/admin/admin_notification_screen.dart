import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      // We add to 'admin_notifications' which will trigger a Cloud Function
      // to broadcast to all users and save to 'notifications' history.
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification sent successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Announcement"),
      ),
      body: _isSending 
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Broadcast Message",
                      style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This will send a push notification to every student and add it to the app's notification history.",
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Notification Title",
                        hintText: "e.g. Campus Holiday Notice",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Message Body",
                        hintText: "Type the details of your announcement here...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.message, color: theme.colorScheme.primary),
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Message body is required" : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _sendNotification,
                        icon: const Icon(Icons.send),
                        label: const Text("Send to All Users", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
