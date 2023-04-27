import 'dart:io';

import 'package:flutter/material.dart';

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