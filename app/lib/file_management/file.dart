import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileData {
  final String id;
  final String name;
  final String url;
  final String path;
  final String type;
  bool downloaded;
  bool decrypted;

  FileData ({
    required this.id,
    required this.name,
    required this.url,
    required this.path,
    required this.type,
    required this.downloaded,
    required this.decrypted,
  });
  
  factory FileData.fromJson(Map<String, dynamic> json, String appDir) {
    final id = md5.convert(utf8.encode(json['name'] + json['url'])).toString();
    final file = File("$appDir${Platform.pathSeparator}$id");
    final exists = file.existsSync();

    return FileData(
      id: id,
      name: json['name'],
      url: json['url'],
      path: file.path,
      type: json['type'],
      downloaded: exists,
      decrypted: false,
    );
  }

  download() async {
    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);
    //final contentLength = response.contentLength;
    
    // _progress = 0;
    // notifyListeners();
  
    final file = File(path);

    List<int> bytes = [];
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        downloaded = true;
        // _progress = bytes.length / contentLength;
        // notifyListeners();
      },
      onDone: () async {
        // _progress = 1;
        // notifyListeners();
        file.writeAsBytes(bytes);
      },
      onError: (e) {
        print(e);
      },
      cancelOnError: true,
    );
  }

  signingIn() async {
    final request = Request('GET', Uri.parse('http://localhost:3000/register'));
    final StreamedResponse response = await Client().send(request);

    
  }

  Widget getData() {
    File file = File(path);
    switch (type) {
      case 'text':
        return Text(file.readAsStringSync());
      
      case 'image':
        return Image.file(file);
        
      default:
        throw Exception('unsupported type');
    }
  }

  // Future<void> test() async {
  //   final algorithm = AesGcm.with256bits();
  //   final secretKey = await algorithm.newSecretKey();

  //   final nonce = algorithm.newNonce();

  //   final clearText = [1, 2, 3];
  //   final secretBox = await algorithm.encrypt(
  //   clearText,
  //   secretKey: secretKey,
  //   nonce: nonce,
  // );
  
  // print('Ciphertext: ${secretBox.cipherText}');
  // print('MAC: ${secretBox.mac}');

  // }

  // =========================================================================

  // Future<void> test() async {
  // final algoX5519 = X25519();

  // // Alice chooses her key pair
  // final aliceKeyPair = await algoX5519.newKeyPair();
  // final alicePrivateKey = await aliceKeyPair.extractPrivateKeyBytes();
  // final alicePublicKey = await aliceKeyPair.extractPublicKey();

  // // Alice knows Bob's public key
  // final bobKeyPair = await algoX5519.newKeyPair();
  // final bobPrivateKey = await bobKeyPair.extractPrivateKeyBytes();
  // final bobPublicKey = await bobKeyPair.extractPublicKey();

  // // Alice calculates the shared secret.
  // final sharedSecret = await algoX5519.sharedSecretKey(
  //   keyPair: aliceKeyPair,
  //   remotePublicKey: bobPublicKey,
  // );
  // final sharedSecretBytes = await aliceKeyPair.extract();

  // print("Alice private key: $alicePrivateKey");
  // print('Alice pub key: $alicePublicKey');

  // print('Bob private key: $bobPrivateKey');
  // print('Bob pub key: $bobPublicKey');
  
  // }

  // =========================================================================
  // Future<void> test() async {
  // // The message that we will sign
  // final message = <int>[1, 2, 3];

  // // Generate a keypair.
  // final algorithm = Ed25519();
  // final keyPair = await algorithm.newKeyPair();

  // // Sign
  // final signature = await algorithm.sign(
  //   message,
  //   keyPair: keyPair,
  // );
  // print('Signature: ${signature.bytes}');
  // print('Public key: ${signature.publicKey}');

  // // Verify signature
  // final isSignatureCorrect = await algorithm.verify(
  //   message,
  //   signature: signature,
  // );
  // print('Correct signature: $isSignatureCorrect');
  // }

  // ========================================================================

  Future<void> test() async {
  // Choose the cipher
  //final algorithm = AesCtr(macAlgorithm: Hmac.sha256());
  final algor = AesCtr.with256bits(macAlgorithm: DartHmac.sha256());

  // Generate a random secret key.
  final secretKey = await algor.newSecretKey();
  final secretKeyBytes = await secretKey.extractBytes();
  print('Secret key: ${secretKeyBytes}');

  // Encrypt
  final secretBox = await algor.encryptString(
    'Hello!',
    secretKey: secretKey,
  );
  print('Nonce: ${secretBox.nonce}'); // Randomly generated nonce
  print('Ciphertext: ${secretBox.cipherText}'); // Encrypted message
  print('MAC: ${secretBox.mac}'); // Message authentication code
  
  // If you are sending the secretBox somewhere, you can concatenate all parts of it:
  final concatenatedBytes = secretBox.concatenation();
  print('All three parts concatenated: $concatenatedBytes');

  // Decrypt
  final clearText = await algor.decryptString(
    secretBox,
    secretKey: secretKey,
  );
  print('Cleartext: $clearText'); // Hello!
  }
}

Future <List<FileData>> fetchFiles() async {
  final response = await get(Uri.parse('http://localhost:3000/files'));
  if (response.statusCode == 200) {
    final docDir = await getApplicationDocumentsDirectory();
    final appDir = Directory("${docDir.path}${Platform.pathSeparator}SecureShare");
    
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }

    List<FileData> list = [];
    jsonDecode(response.body).forEach((v) => list.add(FileData.fromJson(v, appDir.path)));
    return list;
  } else {
    throw Exception('Failed to load Folders');
  }
}
//////////////////////////////////////// Displaying data for Files //////////////////////////////

class DisplayData extends StatefulWidget {
  final FileData file;
  const DisplayData({required this.file, super.key,});
  @override
  State<DisplayData> createState() => _DisplayDataState();
}

class _DisplayDataState extends State<DisplayData> {

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Content')),
      ),
      body: Center (
        child: widget.file.getData(),
      ),
    );
  }
}