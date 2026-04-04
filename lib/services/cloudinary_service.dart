import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // ── Configuration ─────────────────────────────────────────────────────────
  static const String _cloudName = 'dtfulec5o';
  static const String _uploadPreset = 'domfix_upload';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Uploads a single image file to Cloudinary.
  ///
  /// Returns the [secure_url] string on success, or throws a
  /// [CloudinaryException] on failure.
  static Future<String> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl == null || secureUrl.isEmpty) {
          throw CloudinaryException('No secure_url in Cloudinary response.');
        }
        return secureUrl;
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        throw CloudinaryException('Upload failed (${ response.statusCode}): $errorMsg');
      }
    } on SocketException {
      throw CloudinaryException(
          'No internet connection. Please check your network and try again.');
    } on CloudinaryException {
      rethrow;
    } catch (e) {
      throw CloudinaryException('Unexpected error during upload: $e');
    }
  }

  /// Uploads multiple image files and returns a list of secure URLs.
  ///
  /// If [stopOnFirstError] is true (default), aborts on the first failure.
  /// Otherwise it collects all successful URLs, skipping failed ones.
  static Future<List<String>> uploadMultiple(
    List<File> files, {
    bool stopOnFirstError = true,
    void Function(int uploaded, int total)? onProgress,
  }) async {
    final urls = <String>[];

    for (var i = 0; i < files.length; i++) {
      final url = await uploadImage(files[i]);
      urls.add(url);
      onProgress?.call(i + 1, files.length);
    }

    return urls;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _parseErrorMessage(String body) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}

/// Thrown when a Cloudinary operation fails.
class CloudinaryException implements Exception {
  final String message;
  const CloudinaryException(this.message);

  @override
  String toString() => 'CloudinaryException: $message';
}
