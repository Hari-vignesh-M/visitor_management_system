/// Encodes / decodes the content of a visitor QR code.
///
/// The QR holds the server-generated visitor ID with an app prefix
/// (`VMS:12`), so random QR codes (URLs, Wi-Fi codes, ...) are rejected
/// before any API call. A bare ID such as `12` or `VIS001` is also accepted.
class QrPayload {
  const QrPayload._();

  static const String prefix = 'VMS:';
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,40}$');

  static String encode(String visitorId) => '$prefix$visitorId';

  /// Returns the visitor ID, or `null` when the QR content is not valid.
  static String? decode(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.startsWith(prefix)) value = value.substring(prefix.length);
    return _idPattern.hasMatch(value) ? value : null;
  }
}
