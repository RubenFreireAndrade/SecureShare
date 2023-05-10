import 'dart:io';

import 'package:app/utils/file_utils.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';

import '../utils/key_utils.dart';

class User {
  static String name = "";
  static String device = "";
  static Directory appDir = Directory('');

  static void initialize() async {
    User.appDir = await FileUtils.getAppDir();
    // var keyPair = await KeyUtils.getClientKeys();
    // var publicKey = keyPair.publicKey as RSAPublicKey;

    // encodeRSAPublicKey

    // final pem = publicKey;

    // final file = File(fileName);
    // file.writeAsStringSync(pem);
  }

  static void setUserData(String userName, String deviceName) {
    User.name = userName;
    User.device = deviceName;
  }
}