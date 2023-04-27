import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

import 'file_utils.dart';

class KeyUtils {
  // Convert an RSA public key to a JSON string
  static String publicKeyToJson(RSAPublicKey publicKey) {
    return json.encode({
      'modulus': publicKey.modulus?.toString(),
      'exponent': publicKey.exponent?.toString(),
    });
  }

  // Serialize a private key to a JSON string
  static String privateKeyToJson(RSAPrivateKey privateKey) {
    return json.encode({
      'modulus': privateKey.modulus?.toString(),
      'privateExponent': privateKey.privateExponent?.toString(),
      'p': privateKey.p?.toString(),
      'q': privateKey.q?.toString(),
    });
  }

  // Convert a JSON string to an RSA public key
  static RSAPublicKey publicKeyFromJson(String jsonString) {
    final map = json.decode(jsonString);
    final modulus = BigInt.parse(map['modulus']);
    final exponent = BigInt.parse(map['exponent']);
    return RSAPublicKey(modulus, exponent);
  }
  
  // Convert a JSON string to an RSA private key
  static RSAPrivateKey privateKeyFromJson(String jsonString) {
    final map = json.decode(jsonString);
    final modulus = BigInt.parse(map['modulus']);
    final privateExponent = BigInt.parse(map['privateExponent']);
    final p = BigInt.parse(map['p']);
    final q = BigInt.parse(map['q']);
    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  static AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAKeys() {
    final keyGen = RSAKeyGenerator();
    keyGen.init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64), SecureRandom('Fortuna')..seed(KeyParameter(
        Platform.instance.platformEntropySource().getBytes(32)))));
    return keyGen.generateKeyPair();
  }

  static Future<AsymmetricKeyPair<PublicKey, PrivateKey>> getClientKeys() async {
    RSAPublicKey publicKey;
    RSAPrivateKey privateKey;
    
    if ((await FileUtils.fileExists("public_key")) && (await FileUtils.fileExists("private_key"))) {
      final publicKeyJson = await FileUtils.loadFileAsString("public_key");
      final privateKeyJson = await FileUtils.loadFileAsString("private_key");
      
      publicKey = KeyUtils.publicKeyFromJson(publicKeyJson);
      privateKey = KeyUtils.privateKeyFromJson(privateKeyJson);
    } else {
      final keyPair = KeyUtils.generateRSAKeys();
      publicKey = keyPair.publicKey as RSAPublicKey;
      privateKey = keyPair.privateKey as RSAPrivateKey;

      await FileUtils.saveToFile("public_key", KeyUtils.publicKeyToJson(publicKey));
      await FileUtils.saveToFile("private_key", KeyUtils.privateKeyToJson(privateKey));
    }

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
  }

  static Future<RSAPublicKey> getReceiversPublicKey(String userName, String deviceName) async {
    final publicKeyResponse = await http.get(Uri.parse('http://localhost:3000/$userName/$deviceName'));
    final publicKeyResponseObj = json.decode(publicKeyResponse.body);
    if (publicKeyResponse.statusCode != 200)
    {
      throw Exception(publicKeyResponseObj["message"] ?? "UNKNOWN ERROR");
    }
    return KeyUtils.publicKeyFromJson(publicKeyResponseObj["public_key"]);
  }
}