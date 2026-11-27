import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lgu_one/admin/share_import/ai_post_parser.dart';
import 'package:lgu_one/admin/share_import/post_draft.dart';

/// Collapsible "Fill with AI" box at the top of the News and Jobs forms.
/// The admin pastes a post (e.g. from WhatsApp), taps Proceed, and Gemini's
/// reading of it is handed to [onFilled] to fill the form.
class AiFillPanel extends StatefulWidget {
  final ValueChanged<PostDraft> onFilled;

  /// The image already picked in the form, if any. Sent along so AI can read
  /// text on a poster too.
  final File? Function()? currentImage;

  const AiFillPanel({super.key, required this.onFilled, this.currentImage});

  @override
  State<AiFillPanel> createState() => _AiFillPanelState();
}

class _AiFillPanelState extends State<AiFillPanel> {
  final _textController = TextEditingController();
  final _tileController = ExpansibleController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    final text = _textController.text.trim();
    final image = widget.currentImage?.call();
    if (text.isEmpty && image == null) {
      setState(() => _error = 'Paste the post text first.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final draft = await AiPostParser.parse(
        text: text.isEmpty ? null : text,
        image: image,
      );
      if (!mounted) return;
      widget.onFilled(draft);
      _textController.clear();
      _tileController.collapse();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: _tileController,
          leading: Icon(Icons.auto_awesome, color: primary),
          title: const Text('Fill with AI'),
          subtitle: const Text('Paste a post and AI fills the form'),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          children: [
            TextField(
              controller: _textController,
              minLines: 4,
              maxLines: 10,
              keyboardType: TextInputType.multiline,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: const InputDecoration(
                hintText: 'Paste the news or job post here…',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _loading ? null : _proceed,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(_loading ? 'Reading…' : 'Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
