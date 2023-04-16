import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:app/utils/key_utils.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

import 'package:app/utils/file_utils.dart';

import '../utils/encryption_utils.dart';

class FileData {
  final String id;
  final String name;
  final String type;
  final String path;
  final String eKey;
  final int size;
  bool downloaded;
  bool decrypted;

  FileData ({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    required this.eKey,
    required this.size,
    required this.downloaded,
    required this.decrypted,
  });
  
  factory FileData.fromJson(Map<String, dynamic> json, String appDir) {
    final file = File("$appDir${Platform.pathSeparator}${json['id']}");
    final exists = file.existsSync();

    return FileData(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      path: file.path,
      eKey: json['eKey'],
      size: int.parse(json['size']),
      downloaded: exists,
      decrypted: false,
    );
  }

  download() async {
    final request = http.Request('GET', Uri.parse(''));
    final http.StreamedResponse response = await http.Client().send(request);
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
}

Future <List<FileData>> fetchFiles() async {
  final response = await http.get(Uri.parse('http://localhost:3000/files/Rubs'));
  if (response.statusCode == 200) {
    final appDir = await FileUtils.getAppDir();

    List<FileData> list = [];
    jsonDecode(response.body).forEach((v) => list.add(FileData.fromJson(v, appDir.path)));
    return list;
  } else {
    throw Exception('Failed to load Folders');
  }
}

Future <void> uploadFile(String filePath, String userName, String fileType) async {
  final publicKey = await KeyUtils.getReceiversPublicKey(userName);
  final file = File(filePath);

  // Generate a random AES key and IV for each file
  var aesKey = EncryptionUtils.generateRandomBytes(256 ~/ 8); // 256-bit key
  var iv = EncryptionUtils.generateRandomBytes(128 ~/ 8); // 128-bit IV

  // Create AES cipher
  var cipher = EncryptionUtils.createAESCipher(aesKey, iv, true);

  // Encrypt the AES key and IV using RSA encryption with the server's public key
  var rsaCipher = EncryptionUtils.createRSACipher(publicKey, true);
  var encryptedAesKeyAndIv = rsaCipher.process(Uint8List.fromList([...aesKey, ...iv]));

  var request = http.StreamedRequest('POST', Uri.parse('http://localhost:3000/upload'));
  
  // Add headers for original user | Maybe this is not correct?
  request.headers['x-user-name'] = userName;

  // Add headers for encrypted AES key and IV
  request.headers['x-aes-key-iv'] = base64Url.encode(encryptedAesKeyAndIv.toList());

  // Add headers for original file name and file size
  request.headers['x-file-name'] = basename(filePath);
  request.headers['x-file-type'] = fileType;
  request.headers['x-file-size'] = (await file.length()).toString();

  file.openRead().listen((chunk) {
      // Encrypt each chunk of data using AES encryption with a randomly generated key and IV
      var encryptedData = cipher.process(Uint8List.fromList(chunk));
      
      // Send the encrypted data and encrypted AES key and IV to the server
      request.sink.add(encryptedData);
  }, onError: (error) {
      // Handle errors that occur during stream transformation
      print('Error occurred while encrypting chunk: $error');
      request.sink.addError(error);
  }, onDone: () {
      // Notify that the entire file has been read and encrypted
      request.sink.close();
  });
  
  final response = await request.send().then(http.Response.fromStream);
  if (response.statusCode != 200) {
    throw Exception('Failed to upload file');
  }
  // File uploaded successfully
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