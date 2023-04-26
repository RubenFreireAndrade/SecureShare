import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:app/file_management/file.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';

import '../utils/file_utils.dart';
import '../utils/key_utils.dart';

class LogIn {
  void initializeClient() async {
    final keyPair = await KeyUtils.getClientKeys();
    //await KeyUtils.registerNewPublicKey("Rubs", keyPair.publicKey as RSAPublicKey);
    //final receiversPublicKey = await KeyUtils.getReceiversPublicKey("Rubs");

    uploadFile(path.absolute('..\\server\\test2.txt'), "Rubs", "text");

    //print(KeyUtils.publicKeyToJson(receiversPublicKey));
  }
}