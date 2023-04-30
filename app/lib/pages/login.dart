import 'dart:convert';
import 'dart:typed_data';

import 'package:app/pages/test_page.dart';
import 'package:app/utils/auth_utils.dart';
import 'package:flutter/material.dart';
import 'package:app/entities/user.dart';
import 'package:app/utils/encryption_utils.dart';
import 'package:app/utils/key_utils.dart';
import 'package:pointycastle/asymmetric/api.dart';

import 'home.dart';
import 'register.dart';

// class Login {
//   void initializeClient() async {
//     final keyPair = await KeyUtils.getClientKeys();
//     await KeyUtils.registerNewPublicKey("Rubs", "windows", keyPair.publicKey as RSAPublicKey);
//     final receiversPublicKey = await KeyUtils.getReceiversPublicKey("Rubs", "windows");

//     uploadFile(path.absolute('..\\server\\test2.txt'), "Rubs", "windows", "text");

//     print(KeyUtils.publicKeyToJson(receiversPublicKey));
//   }
// }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final inputFieldController = TextEditingController();

  void disposeFieldController() {
    super.dispose();
    inputFieldController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('What Is Your Name?'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(200),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: inputFieldController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Enter Your Name';
                  } else {
                    return null;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  prefixIconColor: Colors.green,
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final userNameValue = inputFieldController.text;

                    KeyUtils.getClientKeys().then((keyPair) {
                      final privateKey = keyPair.privateKey as RSAPrivateKey;
                      final privateRsaCipher = EncryptionUtils.encryptRSACipherPrivate(privateKey);
                      final authKey = base64Url.encode(privateRsaCipher.process(base64Url.decode(userNameValue)).toList());

                      AuthUtils.login(userNameValue, authKey).then((loginResponse) {
                        print(loginResponse['devices']);
                        if (loginResponse['device'] == null) {
                          // Lead user to Register Page.
                          print("user dont exist. pushing Register()");
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Register(userName: userNameValue, devices: loginResponse['devices'])));
                        } else {
                          print("user exists. pushing HomePage()");
                          User.initialize(userNameValue, loginResponse['device']);
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                        }
                      });
                    });
                  }
                }, 
                child: const Text('Check Username')
              )
            ],
          )),
      ),
    );
  }
}