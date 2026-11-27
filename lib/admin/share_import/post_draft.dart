import 'dart:io';

/// Which admin section a shared post belongs in.
enum PostKind { news, job }

/// A news or job post read from a WhatsApp share, used to pre-fill the
/// admin publish forms. The admin reviews it before anything is published.
class PostDraft {
  final PostKind kind;
  final String title;
  final String description;

  /// Apply / registration / info link (jobs). Empty when none.
  final String link;

  /// One of the news types: Admission, Event, Notice, Drive, General.
  final String newsType;

  /// Last day the post stays up, when the message names one.
  final DateTime? expiryDate;

  /// The image shared with the message, if any.
  final File? image;

  const PostDraft({
    required this.kind,
    required this.title,
    required this.description,
    this.link = '',
    this.newsType = 'General',
    this.expiryDate,
    this.image,
  });

  PostDraft copyWith({PostKind? kind}) => PostDraft(
    kind: kind ?? this.kind,
    title: title,
    description: description,
    link: link,
    newsType: newsType,
    expiryDate: expiryDate,
    image: image,
  );
}
