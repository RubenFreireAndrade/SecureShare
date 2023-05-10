import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

class EncryptionUtils {
  static Uint8List generateRandomBytes(int length) {
    var random = SecureRandom('Fortuna')..seed(KeyParameter(
        Platform.instance.platformEntropySource().getBytes(32)));
    return random.nextBytes(length);
  }

  static PaddedBlockCipherImpl createAESCipher(Uint8List key, Uint8List iv, bool forEncryption) {
    assert([128, 192, 256].contains(key.length * 8));
    assert(128 == iv.length * 8);

    final cipher = PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(BlockCipher("AES")))
      ..init(forEncryption, PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, KeyParameter>(ParametersWithIV<KeyParameter>(KeyParameter(key), iv), null));
    return cipher;
  }

  static OAEPEncoding encryptRSACipherPublic(RSAPublicKey publicKey) {
    var cipher = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return cipher;
  }

  static PKCS1Encoding encryptRSACipherPrivate(RSAPrivateKey privateKey) {
    var cipher = PKCS1Encoding(RSAEngine())
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher;
  }

  static OAEPEncoding decryptRSACipher(RSAPrivateKey privateKey) {
    var cipher = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher;
  }
}