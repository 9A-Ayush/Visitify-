import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  // Cloudinary credentials
  static const String cloudName = 'dougea9lu';
  static const String uploadPreset = 'chatkaro';
  static const String apiKey = '974189435238585';
  static const String apiSecret = '20mz2spe8wwfwA0Z25-ANScmX4w';

  static Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      // Validate configuration
      if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
        print('ERROR: Cloudinary configuration is missing!');
        print('cloudName: ${cloudName.isEmpty ? "EMPTY" : "OK"}');
        print('apiKey: ${apiKey.isEmpty ? "EMPTY" : "OK"}');
        print('apiSecret: ${apiSecret.isEmpty ? "EMPTY" : "OK"}');
        return null;
      }
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Use signed upload (no preset required)
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = apiKey;
      
      // Optional: add folder if specified
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Generate signature for signed upload
      final signature = _generateSignatureForUpload(timestamp, folder);
      request.fields['signature'] = signature;

      print('DEBUG: Using signed upload to Cloudinary...');
      print('DEBUG: Cloud: $cloudName, Folder: ${folder ?? "none"}');

      final response = await request.send();

      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData);
        print('DEBUG: Cloudinary upload successful!');
        return jsonData['secure_url'] as String;
      } else {
        print('ERROR: Cloudinary upload failed with status: ${response.statusCode}');
        print('ERROR: Response body: $responseData');
        return null;
      }
    } catch (e) {
      print('ERROR: Exception uploading to Cloudinary: $e');
      return null;
    }
  }

  static Future<String?> uploadImageFromBytes(
    List<int> imageBytes,
    String fileName, {
    String? folder,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // Add the image bytes
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
      );

      // Use signed upload (no preset required)
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = apiKey;
      
      // Optional: add folder if specified
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Generate signature for signed upload
      final signature = _generateSignatureForUpload(timestamp, folder);
      request.fields['signature'] = signature;

      final response = await request.send();

      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData);
        print('DEBUG: Cloudinary upload successful!');
        return jsonData['secure_url'] as String;
      } else {
        print('ERROR: Cloudinary upload failed with status: ${response.statusCode}');
        print('ERROR: Response body: $responseData');
        return null;
      }
    } catch (e) {
      print('ERROR: Exception uploading to Cloudinary: $e');
      return null;
    }
  }

  static String _generateSignature(int timestamp, String? folder) {
    // Create the string to sign
    final paramsToSign = <String, String>{
      'timestamp': timestamp.toString(),
      'upload_preset': uploadPreset,
    };

    if (folder != null) {
      paramsToSign['folder'] = folder;
    }

    // Sort parameters alphabetically
    final sortedParams =
        paramsToSign.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Create query string
    final queryString = sortedParams
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Add API secret
    final stringToSign = '$queryString$apiSecret';

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  static String _generateSignatureForUpload(int timestamp, String? folder) {
    // Create the string to sign for direct upload (no preset)
    final paramsToSign = <String, String>{
      'timestamp': timestamp.toString(),
    };

    if (folder != null) {
      paramsToSign['folder'] = folder;
    }

    // Sort parameters alphabetically
    final sortedParams =
        paramsToSign.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Create query string
    final queryString = sortedParams
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Add API secret
    final stringToSign = '$queryString$apiSecret';

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  static Future<bool> deleteImage(String publicId) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Generate signature for deletion
      final paramsToSign = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };

      final sortedParams =
          paramsToSign.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      final queryString = sortedParams
          .map((entry) => '${entry.key}=${entry.value}')
          .join('&');

      final stringToSign = '$queryString$apiSecret';
      final bytes = utf8.encode(stringToSign);
      final signature = sha1.convert(bytes).toString();

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['result'] == 'ok';
      }

      return false;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  // Helper method to extract public ID from Cloudinary URL
  static String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the segment after 'upload' or 'image/upload'
      int uploadIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'upload') {
          uploadIndex = i;
          break;
        }
      }

      if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
        // Skip version (v1234567890) and get the public ID
        final publicIdWithExtension = pathSegments
            .sublist(uploadIndex + 2)
            .join('/');
        // Remove file extension
        final lastDotIndex = publicIdWithExtension.lastIndexOf('.');
        if (lastDotIndex != -1) {
          return publicIdWithExtension.substring(0, lastDotIndex);
        }
        return publicIdWithExtension;
      }

      return null;
    } catch (e) {
      print('Error extracting public ID: $e');
      return null;
    }
  }

  // Transform image URL for different sizes
  static String getTransformedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop = 'fill',
    String? quality = 'auto',
  }) {
    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      // Find upload segment
      int uploadIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'upload') {
          uploadIndex = i;
          break;
        }
      }

      if (uploadIndex != -1) {
        // Build transformation string
        final transformations = <String>[];

        if (width != null) transformations.add('w_$width');
        if (height != null) transformations.add('h_$height');
        if (crop != null) transformations.add('c_$crop');
        if (quality != null) transformations.add('q_$quality');

        if (transformations.isNotEmpty) {
          pathSegments.insert(uploadIndex + 1, transformations.join(','));
        }

        return uri.replace(pathSegments: pathSegments).toString();
      }

      return originalUrl;
    } catch (e) {
      print('Error transforming URL: $e');
      return originalUrl;
    }
  }
}
