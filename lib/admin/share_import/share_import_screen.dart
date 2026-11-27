import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lgu_one/admin/admin_jobs_screen.dart';
import 'package:lgu_one/admin/admin_news_screen.dart';
import 'package:lgu_one/admin/share_import/ai_post_parser.dart';
import 'package:lgu_one/admin/share_import/post_draft.dart';

/// Reads a shared WhatsApp post with AI, then opens the News or Jobs form
/// filled in for the admin to check and publish.
class ShareImportScreen extends StatefulWidget {
  final String? text;
  final File? image;

  const ShareImportScreen({super.key, this.text, this.image});

  @override
  State<ShareImportScreen> createState() => _ShareImportScreenState();
}

class _ShareImportScreenState extends State<ShareImportScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    setState(() => _error = null);
    try {
      final draft = await AiPostParser.parse(
        text: widget.text,
        image: widget.image,
      );
      if (!mounted) return;
      _open(draft);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _open(PostDraft draft) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => draft.kind == PostKind.job
            ? AdminJobsScreen(draft: draft)
            : AdminNewsScreen(draft: draft),
      ),
    );
  }

  /// Opens a form with the raw message when AI is unavailable.
  void _fillManually(PostKind kind) {
    _open(
      PostDraft(
        kind: kind,
        title: '',
        description: widget.text?.trim() ?? '',
        image: widget.image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Post from WhatsApp')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _error == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Reading the post with AI…',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _read,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => _fillManually(PostKind.news),
                            child: const Text('Fill News myself'),
                          ),
                          OutlinedButton(
                            onPressed: () => _fillManually(PostKind.job),
                            child: const Text('Fill Job myself'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
