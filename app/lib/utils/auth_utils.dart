import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pointycastle/pointycastle.dart';

import 'key_utils.dart';

class AuthUtils {
  static Future<void> registerNewDevice(String userName, String deviceName, RSAPublicKey publicKey) async {
    final publicKeyJson = KeyUtils.publicKeyToJson(publicKey);

    final http.Response response = await http.post(
      Uri.parse('http://localhost:3000/register'),
      body: {
        'userName': userName,
        'deviceName': deviceName,
        'publicKey': publicKeyJson
      },
    );

    if (response.statusCode == 200) {
      print('Public key registered successfully');
    } else {
      print('Failed to register public key: ${response.reasonPhrase}');
    }
  }

  static Future<Map<String, dynamic>> login(String userName, String authKey) async {
    final http.Response response = await http.post(
      Uri.parse('http://localhost:3000/login'),
      body: {
        'userName': userName,
        'authKey': authKey
      },
    );
    return jsonDecode(response.body);
  }
}