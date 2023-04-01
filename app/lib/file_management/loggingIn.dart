import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';

import '../utils/file_utils.dart';
import '../utils/key_utils.dart';


class LoggingIn {
  void runMain() async {
    final keyPair = await KeyUtils.getClientKeys();
    await KeyUtils.registerNewPublicKey("Rubs", keyPair.publicKey as RSAPublicKey);
    final receiversPublicKey = await KeyUtils.getReceiversPublicKey("Rubs");

    print(KeyUtils.publicKeyToJson(receiversPublicKey));
  }
}