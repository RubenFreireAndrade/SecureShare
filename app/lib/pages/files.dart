import 'dart:io';

import 'package:app/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../entities/file_data.dart';

import 'file_view.dart';

class Files extends StatefulWidget {
  const Files({super.key});

  @override
  State<Files> createState() => _FilesState();
}

class _FilesState extends State<Files> {
  late Future<List<FileData>> files;

  @override
  void initState() {
    super.initState();
    files = FileUtils.getFiles();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Files')),
      ),
      body: Center(
          child: Column( 
            children: [
               ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    allowedExtensions: ['png', 'jpg', 'txt'],
                    );

                  if (result != null) {
                    for (PlatformFile f in result.files) {
                      final deconstructedName = f.name.split('.');
                      final extension = deconstructedName[deconstructedName.length - 1];
                      final fileType = ['png', 'jpg'].contains(extension) ? "image" : "text";
                      FileUtils.uploadFile(path.absolute(f.path!), "Rubs", "Windows", fileType);
                    }
                  } else {
                    // User canceled the picker
                  }
                }, 
                child: const Text('Upload File'),
              ),
              FutureBuilder<List<FileData>>(
                future: files,
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
                              await FileUtils.downloadFile(file);
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (context) => FileView(file: file),));
                          }
                        ),
                        Text(file.name),
                      ];
                      if (file.downloaded) {
                        c.add(const Icon(Icons.verified));
                      }
                      return Column(children: c);
                    }).toList(),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                throw Exception('Because it told me to');
              },
            ),
            ],
          )
      ),
    );
  }
}