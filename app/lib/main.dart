import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

import 'chat_management/chat.dart';
import 'file_management/file.dart';

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  FlutterDownloader.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('SecureShare'),
        centerTitle: true,
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Icon(Icons.folder),
          Icon(Icons.chat)
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Center(child: Text('Navigation')),
            ),
            ListTile(
              title: const Center(child: Text('Chat')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder:(context) => const Chat(),));
              },
            ),
            ListTile(
              title: const Center(child: Text('Files')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder:(context) => const Files(),));
              },
            ),
          ],
        ),
      ),
    );
  }
}
/////////////////////////////////////////// Seperated custom Classes /////////////////////////////////////////////

class Files extends StatefulWidget {
  const Files({super.key});

  @override
  State<Files> createState() => _FilesState();
}

class _FilesState extends State<Files> {
  late Future<List<FileData>> futureFiles;

  @override
  void initState() {
    super.initState();
    futureFiles = fetchFiles();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Files')),
      ),
      body: Center(
          child: FutureBuilder<List<FileData>>(
            future: futureFiles,
            builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: snapshot.data!.map((file) { 
                  List<Widget> c = [
                    IconButton(
                      icon: const Icon(Icons.folder),
                      iconSize: 100,
                      onPressed: () async {
                        if (!file.downloaded) {
                          await file.download();
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DisplayData(file: file),));
                      }
                    ),
                  ];
                  if (file.downloaded) {
                    c.add(const Icon(Icons.verified));
                  }
                  return Column(children: c );
                }).toList(),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            throw Exception('Not loaded properly');
          },
        ),
      ),
    );
  }
}

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Chat')),
      ),
    );
  }
}