import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String _apiKey = 'ec47a2ec2f7d6faed7d0e6df2f4fb65a';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads an image file to ImgBB and returns the URL of the uploaded image.
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['url'];
        }
      } else {
        print('ImgBB Upload Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ImgBB Exception: $e');
    }
    return null;
  }
}
