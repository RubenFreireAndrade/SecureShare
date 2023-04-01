import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;

class FileUtils {
  static Future<Directory> getAppDir() async {
    final docDir = await path_provider.getApplicationDocumentsDirectory();
    final appDir = Directory("${docDir.path}${Platform.pathSeparator}SecureShare");
    
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }
    return appDir;
  }

  static Future<File> getFile(String name) async {
    final appDir = await FileUtils.getAppDir();
    return File("${appDir.path}${Platform.pathSeparator}$name");
  }

  static Future<File> saveToFile(String name, String data) async {
    final file = await FileUtils.getFile(name);
    file.writeAsStringSync(data);
    return file;
  }

  static Future<String> loadFileAsString(String name) async {
    final file = await FileUtils.getFile(name);
    return file.readAsStringSync();
  }

  static Future<bool> fileExists(String name) async {
    final file = await FileUtils.getFile(name);
    return file.existsSync();
  }
}