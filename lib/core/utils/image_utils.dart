import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Returns a safe [CachedNetworkImageProvider] if [url] is a valid HTTP/HTTPS URL with a host.
/// Returns `null` if [url] is null, empty, or malformed, preventing "No host specified in URI" errors.
ImageProvider? safeNetworkImageProvider(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    return null;
  }
  try {
    final uri = Uri.parse(trimmed);
    if (!uri.hasScheme || uri.host.isEmpty) return null;
    return CachedNetworkImageProvider(trimmed);
  } catch (_) {
    return null;
  }
}
