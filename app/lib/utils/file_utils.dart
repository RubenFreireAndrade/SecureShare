import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:pointycastle/pointycastle.dart';

import '../entities/file_data.dart';
import '../entities/user.dart';
import 'encryption_utils.dart';
import 'key_utils.dart';

class FileUtils {
  static Future<Directory> getAppDir() async {
    final docDir = await path_provider.getApplicationDocumentsDirectory();
    final appDir = Directory("${docDir.path}${Platform.pathSeparator}SecureShare");
    
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }
    return appDir;
  }

  static File getFile(String name) {
    return File("${User.appDir.path}${Platform.pathSeparator}$name");
  }

  static File saveToFile(String name, String data) {
    final file = FileUtils.getFile(name);
    file.writeAsStringSync(data);
    return file;
  }

  static String loadFileAsString(String name) {
    final file = FileUtils.getFile(name);
    return file.readAsStringSync();
  }

  static bool fileExists(String name) {
    final file = FileUtils.getFile(name);
    return file.existsSync();
  }

  static FileData fileDataFromJson(Map<String, dynamic> json) {
    final file = File("${User.appDir.path}${Platform.pathSeparator}${json['id']}");
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

  static Future <List<FileData>> getFiles() async {
    final response = await http.get(Uri.parse('http://localhost:3000/${User.name}/${User.device}/files'));
    if (response.statusCode == 200) {
      List<FileData> list = [];
      jsonDecode(response.body).forEach((v) => list.add(fileDataFromJson(v)));
      return list;
    } else {
      throw Exception('Failed to load Folders');
    }
  }

  static void downloadFile(FileData f) async {
    final request = http.Request('GET', Uri.parse('http://localhost:3000/${User.name}/${User.device}/${f.id}'));

    final http.StreamedResponse response = await http.Client().send(request);

    final file = FileUtils.getFile(f.id);
    final writeStream = file.openWrite();

    final keyPair = await KeyUtils.getClientKeys();

    // Decrypt the AES key and IV using RSA decryption with the user's private key
    final rsaCipher = EncryptionUtils.decryptRSACipher(keyPair.privateKey as RSAPrivateKey);
    final decryptedAesKeyAndIv = rsaCipher.process(base64Url.decode(f.eKey));
    final aesKey = decryptedAesKeyAndIv.sublist(0, 256 ~/ 8);
    final iv = decryptedAesKeyAndIv.sublist(256 ~/ 8);

    // Create AES cipher
    var cipher = EncryptionUtils.createAESCipher(aesKey, iv, false);

    await for (var chunk in response.stream)
    {
      writeStream.add(cipher.process(Uint8List.fromList(chunk)));
    }

    await writeStream.flush();
    await writeStream.close();
  }

  static Future <void> uploadFile(String filePath, String userName, String deviceName, String fileType) async {
    final publicKey = await KeyUtils.getReceiversPublicKey(userName, deviceName);
    final file = File(filePath);

    // Generate a random AES key and IV for each file
    var aesKey = EncryptionUtils.generateRandomBytes(256 ~/ 8); // 256-bit key
    var iv = EncryptionUtils.generateRandomBytes(128 ~/ 8); // 128-bit IV

    // Create AES cipher
    var cipher = EncryptionUtils.createAESCipher(aesKey, iv, true);

    // Encrypt the AES key and IV using RSA encryption with the server's public key
    var rsaCipher = EncryptionUtils.encryptRSACipherPublic(publicKey);
    var encryptedAesKeyAndIv = rsaCipher.process(Uint8List.fromList([...aesKey, ...iv]));

    var request = http.StreamedRequest('POST', Uri.parse('http://localhost:3000/upload'));
    
    // Add headers for original user | Maybe this is not correct?
    request.headers['x-user-name'] = userName;
    request.headers['x-device-name'] = deviceName;

    // Add headers for encrypted AES key and IV
    request.headers['x-e-key'] = base64Url.encode(encryptedAesKeyAndIv.toList());

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
}