import 'dart:io';
import 'dart:async';
import 'dart:convert';
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