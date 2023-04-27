import 'dart:io';

import 'package:app/utils/file_utils.dart';

class User {
  static String name = "";
  static String device = "";
  static Directory appDir = Directory('');

  static void initialize(String userName, String deviceName) async {
    User.name = userName;
    User.device = deviceName;
    User.appDir = await FileUtils.getAppDir();
  }
}