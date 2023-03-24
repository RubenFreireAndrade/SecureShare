import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
// import 'package:cryptography/cryptography.dart';
// import 'package:cryptography/dart.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';

class LoggingIn {

  void signingIn() async {
    final pair = generateRSAkeyPair(exampleSecureRandom());
    final publicModulus = pair.publicKey.modulus;
    final publicExponent = pair.publicKey.publicExponent;

    final privateModulus = pair.privateKey.modulus; // is the product of privateKey * prime num
    final privateExponent = pair.privateKey.privateExponent;
    final privatePublicExponent = pair.privateKey.publicExponent;

    print("Private Key Modulus: $privateModulus");
    print("Private Key exponent: $privateExponent");
    print("Private Key private Public Exponent: $privatePublicExponent");

    var publicKey = RSAPublicKey(BigInt.parse("$publicModulus"), BigInt.parse("$publicExponent"));

    // final request = Request('POST', Uri.parse('http://localhost:3000/register'));
    // final StreamedResponse response = await Client().send(request);
    // print("called: ${request.url}");

    


    var data = utf8.encode("Testing encryption");

    var encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    var encrypedData = encryptor.process(Uint8List.fromList(data));
    print("Encrypted Data: $encrypedData");

    var encryptedDataString = base64Encode(encrypedData);
    print("Encrypted Data String: $encryptedDataString");
  }

  void generateKey() async {

    // WORKING.
  // final algoX5519 = X25519();

  // // Alice chooses her key pair
  // final aliceKeyPair = await algoX5519.newKeyPair();
  // final alicePrivateKey = await aliceKeyPair.extractPrivateKeyBytes();
  // final alicePublicKey = await aliceKeyPair.extractPublicKey();

  // // // Alice knows Bob's public key
  // // final bobKeyPair = await algoX5519.newKeyPair();
  // // final bobPrivateKey = await bobKeyPair.extractPrivateKeyBytes();
  // // final bobPublicKey = await bobKeyPair.extractPublicKey();

  // // // Alice calculates the shared secret.
  // // final sharedSecret = await algoX5519.sharedSecretKey(
  // //   keyPair: aliceKeyPair,
  // //   remotePublicKey: bobPublicKey,
  // // );
  // // final sharedSecretBytes = await aliceKeyPair.extract();

  // print("Alice private key: $alicePrivateKey");
  // print('Alice pub key: $alicePublicKey');

  // print('Bob private key: $bobPrivateKey');
  // print('Bob pub key: $bobPublicKey');

  // =========================================================================
  }

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(SecureRandom secureRandom, {int bitLength = 2048}) {
    final keyGen = RSAKeyGenerator();

    keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      secureRandom));

    final pair = keyGen.generateKeyPair();

    final myPublic = pair.publicKey as RSAPublicKey;
    final myPrivate = pair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
  }

  SecureRandom exampleSecureRandom(){
    final secureRandom = SecureRandom('Fortuna')..seed(KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));
    return secureRandom;
  }
}