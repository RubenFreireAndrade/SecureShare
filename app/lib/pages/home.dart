import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../utils/file_utils.dart';
import 'files.dart';
import 'chats.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  void initState() {
  }

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
          // TODO = Change this make it appealing.
          Icon(Icons.folder),
          Icon(Icons.chat),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Center(
                child: Text('Navigation', style: TextStyle(fontSize: 20))
              ),
            ),
            ListTile(
              title: const Center(
                child: Text('Chat', style: TextStyle(fontSize: 20))
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder:(context) => const Chats(),));
              },
            ),
            ListTile(
              title: const Center(
                child: Text('Files', style: TextStyle(fontSize: 20))
              ),
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