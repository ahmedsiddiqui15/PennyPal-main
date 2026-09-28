import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config/cloudinary_config.dart';

class CloudinaryException implements Exception {
  const CloudinaryException(this.message);

  final String message;

  @override
  String toString() => 'CloudinaryException: $message';
}

class CloudinaryService {
  CloudinaryService({
    http.Client? client,
    String? cloudName,
    String? uploadPreset,
  })  : _client = client ?? http.Client(),
        _cloudName = cloudName ?? CloudinaryConfig.cloudName,
        _uploadPreset = uploadPreset ?? CloudinaryConfig.uploadPreset;

  final http.Client _client;
  final String _cloudName;
  final String _uploadPreset;

  static const Duration _timeout = Duration(seconds: 60);

  bool get isConfigured =>
      _cloudName.trim().isNotEmpty && _uploadPreset.trim().isNotEmpty;

  
  
  
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String folder = CloudinaryConfig.avatarFolder,
  }) async {
    if (!isConfigured) {
      throw const CloudinaryException(
        'Cloudinary is not set up. Add CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET to enable image uploads.',
      );
    }

    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl(_cloudName)),
    )
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    final http.Response response;
    try {
      final http.StreamedResponse streamed =
          await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const CloudinaryException(
        'Could not reach Cloudinary. Check your connection and try again.',
      );
    }

    final Map<String, dynamic> body;
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const CloudinaryException(
          'Cloudinary returned an unexpected response.',
        );
      }
      body = decoded;
    } on CloudinaryException {
      rethrow;
    } catch (_) {
      throw const CloudinaryException(
        'Cloudinary returned an unexpected response.',
      );
    }

    if (response.statusCode != 200) {
      final Object? error = body['error'];
      final String message =
          error is Map<String, dynamic> && error['message'] is String
              ? error['message'] as String
              : 'Cloudinary upload failed (${response.statusCode}).';
      throw CloudinaryException(message);
    }

    final Object? url = body['secure_url'] ?? body['url'];
    if (url is! String || url.isEmpty) {
      throw const CloudinaryException(
        'Cloudinary did not return an image URL.',
      );
    }
    return url;
  }

  void dispose() => _client.close();
}
