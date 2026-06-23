import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class StorageService {
  // Setup (free, no credit card):
  // 1. Create account at cloudinary.com
  // 2. Dashboard → Settings → Upload → Add upload preset → Mode: Unsigned → Name: foodshare_unsigned
  // 3. Copy your Cloud Name from the dashboard home page
  static const _cloudName = 'YOUR_CLOUD_NAME';
  static const _uploadPreset = 'foodshare_unsigned';

  static bool get isConfigured => _cloudName != 'YOUR_CLOUD_NAME';

  static Future<String> uploadDonationImage(File file) async {
    if (!isConfigured) {
      throw Exception(
        'Cloudinary not configured. Set _cloudName in storage_service.dart.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
    );
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Image upload failed: $body');
    }

    return jsonDecode(body)['secure_url'] as String;
  }
}
