import 'package:flutter/material.dart';

import '../entities/file_data.dart';

class FileView extends StatefulWidget {
  final FileData file;
  const FileView({required this.file, super.key,});
  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {

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