import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/dart.dart';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'dart:typed_data';
import 'package:pointycastle/api.dart' as pointy_castle_api;
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/random/auto_seed_block_ctr_random.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart' as pointy_castle_platform;

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed_algor;

import 'package:encrypt/encrypt.dart' as encrypt;


class LoggingIn {
  Future<File> saveToFile(Map<String, dynamic> data) async {
    final docDir = await path_provider.getApplicationDocumentsDirectory();
    final appDir = Directory("${docDir.path}${Platform.pathSeparator}SecureShare");
    final file = File(appDir.path);
    
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }

    final jsonData = jsonEncode(data);
    file.writeAsStringSync(jsonData);

    return file;
  }

  void signingIn() async {
    // final algoEd = Ed25519();

    // // Alice chooses her key pair
    // final aliceKeyPair = await algoEd.newKeyPair();
    // final alicePrivateKey = await aliceKeyPair.extractPrivateKeyBytes();
    // final alicePublicKey = await aliceKeyPair.extractPublicKey();

    // print("Alice private key: $alicePrivateKey");
    // print('Alice pub key: $alicePublicKey');
  }

  void generateKeysAndStoreToFile() async {
    //Generate a new key pair
    final keyPair = ed_algor.generateKey();

    // Get the public and private keys as bytes
    final publicKeyBytes = keyPair.publicKey.bytes;
    final privateKeyBytes = keyPair.privateKey.bytes;

    // Store the keys in files
    final publicKeyFile = File('public_key.bin');
    //publicKeyFile.writeAsBytesSync(publicKeyBytes);
    final privateKeyFile = File('private_key.bin');
    //privateKeyFile.writeAsBytesSync(privateKeyBytes);

    // print(publicKeyBytes);
    // print(privateKeyBytes);

    if (publicKeyFile.existsSync() && privateKeyFile.existsSync()) {
      final publicKeyBytes = publicKeyFile.readAsBytesSync();
      final privateKeyBytes = privateKeyFile.readAsBytesSync();

      final publicKey = ed_algor.PublicKey(publicKeyBytes);
      final privateKey = ed_algor.PrivateKey(privateKeyBytes);

      final keyPair = ed_algor.KeyPair(privateKey, publicKey);
      
      print('Loaded key pair: ${keyPair.publicKey.bytes}');
      print('Loaded key pair: ${keyPair.privateKey.bytes}');
    } else {
      final keyPair = ed_algor.generateKey();

      publicKeyFile.writeAsBytesSync(keyPair.publicKey.bytes);
      privateKeyFile.writeAsBytesSync(keyPair.privateKey.bytes);

      print('Generated key pair: ${keyPair.publicKey.bytes}');
      print('Generated key pair: ${keyPair.privateKey.bytes}');
    }
  }
}