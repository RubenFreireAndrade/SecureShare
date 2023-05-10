import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

import 'file_utils.dart';

class KeyUtils {
  // Convert an RSA public key to a PEM string
  static String publicKeyToPEM(RSAPublicKey publicKey) {
    final asn1Sequence = ASN1Sequence()
      ..add(ASN1Integer(publicKey.modulus))
      ..add(ASN1Integer(publicKey.exponent));

    final derPublicKey = asn1Sequence.encode();

    return '''-----BEGIN RSA PUBLIC KEY-----\n${const Base64Encoder().convert(derPublicKey)}\n-----END RSA PUBLIC KEY-----''';
  }

  // Serialize a private key to a PEM string
  static String privateKeyToPEM(RSAPrivateKey privateKey) {
    final privateKeySequence = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero))
      ..add(ASN1Integer(privateKey.modulus))
      ..add(ASN1Integer(privateKey.publicExponent))
      ..add(ASN1Integer(privateKey.privateExponent))
      ..add(ASN1Integer(privateKey.p))
      ..add(ASN1Integer(privateKey.q));

    final derPrivateKey = privateKeySequence.encode();

    return '''-----BEGIN RSA PRIVATE KEY-----\n${const Base64Encoder().convert(derPrivateKey)}\n-----END RSA PRIVATE KEY-----''';
  }

  // Convert a PEM string to an RSA public key
  static RSAPublicKey publicKeyFromPEM(String pemString) {
    return encrypt.RSAKeyParser().parse(pemString) as RSAPublicKey;
  }
  
  // Convert a PEM string to an RSA private key
  static RSAPrivateKey privateKeyFromPEM(String pemString) {
    return encrypt.RSAKeyParser().parse(pemString) as RSAPrivateKey;
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
    
    if ((FileUtils.fileExists("public_key")) && (FileUtils.fileExists("private_key"))) {
      final publicKeyJson = FileUtils.loadFileAsString("public_key");
      final privateKeyJson = FileUtils.loadFileAsString("private_key");
      
      publicKey = KeyUtils.publicKeyFromPEM(publicKeyJson);
      privateKey = KeyUtils.privateKeyFromPEM(privateKeyJson);
    } else {
      final keyPair = KeyUtils.generateRSAKeys();
      publicKey = keyPair.publicKey as RSAPublicKey;
      privateKey = keyPair.privateKey as RSAPrivateKey;

      FileUtils.saveToFile("public_key", KeyUtils.publicKeyToPEM(publicKey));
      FileUtils.saveToFile("private_key", KeyUtils.privateKeyToPEM(privateKey));
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
    return KeyUtils.publicKeyFromPEM(publicKeyResponseObj["public_key"]);
  }
}