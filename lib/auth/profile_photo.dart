import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Image provider for a profile photo URL.
///
/// On web, Firebase Storage and Google photo URLs are cross-origin without
/// CORS headers, so Flutter cannot download them itself; falling back to a
/// plain <img> element lets the browser show them. Must be drawn with an
/// [Image] widget (not a decoration) for that fallback to work.
ImageProvider profilePhotoProvider(String url) => kIsWeb
    ? NetworkImage(url, webHtmlElementStrategy: WebHtmlElementStrategy.fallback)
    : CachedNetworkImageProvider(url);

/// The photo a profile should show: a stored `photoUrl` (null means the
/// student removed it), else the Google account photo.
String? profilePhotoUrl(Map<String, dynamic> data, String? googlePhoto) {
  final url = data.containsKey('photoUrl')
      ? data['photoUrl']?.toString()
      : googlePhoto;
  return (url == null || url.isEmpty) ? null : url;
}
