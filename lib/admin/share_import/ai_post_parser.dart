import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:intl/intl.dart';
import 'package:lgu_one/admin/share_import/ai_firebase.dart';
import 'package:lgu_one/admin/share_import/post_draft.dart';

/// Thrown with a message that is safe to show to the admin.
class AiParseException implements Exception {
  final String message;
  const AiParseException(this.message);

  @override
  String toString() => message;
}

/// Uses Gemini (Firebase AI Logic, Gemini Developer API free tier) to split a
/// shared WhatsApp post into the fields of a news or job post.
class AiPostParser {
  AiPostParser._();

  /// Change here if Google retires this model.
  static const String modelName = 'gemini-3.5-flash-lite';

  static const List<String> newsTypes = [
    'Admission',
    'Event',
    'Notice',
    'Drive',
    'General',
  ];

  static GenerativeModel? _cached;

  /// Built on first use, against the free AI project (see [AiFirebase]).
  static Future<GenerativeModel> _model() async => _cached ??=
      FirebaseAI.googleAI(app: await AiFirebase.app).generativeModel(
        model: modelName,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'kind': Schema.enumString(
                enumValues: ['news', 'job'],
                description:
                    'job for jobs, internships, hiring or career openings; '
                    'news for everything else.',
              ),
              'title': Schema.string(
                description: 'Short clear headline, at most 80 characters.',
              ),
              'description': Schema.string(
                description:
                    'The full details as clean readable text: who, what, '
                    'eligibility, dates, venue, how to apply. Keep all facts. '
                    'No title repeated, no links, no emojis spam, no '
                    'WhatsApp *bold* markers.',
              ),
              'link': Schema.string(
                description:
                    'The main apply / registration / info URL, or empty string.',
              ),
              'newsType': Schema.enumString(
                enumValues: newsTypes,
                description:
                    'For news: Admission, Event, Notice, Drive (recruitment '
                    'drives) or General.',
              ),
              'expiryDate': Schema.string(
                description:
                    'Deadline or last relevant day as YYYY-MM-DD, or empty '
                    'string when the post names none.',
              ),
            },
            optionalProperties: ['link', 'newsType', 'expiryDate'],
          ),
        ),
      );

  /// Reads the shared [text] and/or [image] and returns a draft to review.
  static Future<PostDraft> parse({String? text, File? image}) async {
    final hasText = text != null && text.trim().isNotEmpty;
    if (!hasText && image == null) {
      throw const AiParseException('Nothing was shared to read.');
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final parts = <Part>[
      TextPart(
        'You turn WhatsApp posts for a university app (Lahore Garrison '
        'University) into structured news or job posts. Today is $today; '
        'resolve relative dates like "this Friday" against it. If an image '
        'is included it is usually a poster: read its text too.\n\n'
        'Post:\n${hasText ? text.trim() : '(image only)'}',
      ),
    ];
    if (image != null) {
      parts.add(InlineDataPart(_mimeOf(image.path), await image.readAsBytes()));
    }

    final GenerateContentResponse response;
    try {
      final model = await _model();
      response = await model.generateContent([Content.multi(parts)]);
    } on FirebaseAIException catch (e) {
      throw AiParseException('AI could not read the post: ${e.message}');
    } catch (e) {
      throw AiParseException('AI could not read the post: $e');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.text ?? '') as Map<String, dynamic>;
    } catch (_) {
      throw const AiParseException('AI gave an answer that could not be read.');
    }

    String field(String key) => (data[key] ?? '').toString().trim();
    final newsType = field('newsType');
    var expiry = DateTime.tryParse(field('expiryDate'));
    // A deadline already gone is useless (and the date picker rejects it).
    final now = DateTime.now();
    if (expiry != null &&
        expiry.isBefore(DateTime(now.year, now.month, now.day))) {
      expiry = null;
    }

    return PostDraft(
      kind: field('kind') == 'job' ? PostKind.job : PostKind.news,
      title: field('title'),
      description: field('description'),
      link: field('link'),
      newsType: newsTypes.contains(newsType) ? newsType : 'General',
      expiryDate: expiry == null
          ? null
          : DateTime(expiry.year, expiry.month, expiry.day, 23, 59, 59),
      image: image,
    );
  }

  static String _mimeOf(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
