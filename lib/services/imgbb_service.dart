import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgbbService {
  static const String _apiKey = '7863e340e39422650aa00494046bdb16';

  static Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['key'] = _apiKey
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final json = jsonDecode(resStr);
      return json['data']['url'];
    } else {
      final resStr = await response.stream.bytesToString();
      throw Exception('Failed to upload image to ImgBB: $resStr');
    }
  }
}
