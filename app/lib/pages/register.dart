import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';

import '../entities/user.dart';
import '../utils/auth_utils.dart';
import '../utils/key_utils.dart';

import 'home.dart';

class Register extends StatefulWidget {
  final String userName;
  final List<dynamic> devices;
  const Register({required this.userName, required this.devices, super.key});

  @override
  State<Register> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register> {
  String? selectedValue = "Windows";

  final formKey = GlobalKey<FormState>();
  final userNameFieldController = TextEditingController();
  final deviceNameFieldController = TextEditingController();

  void disposeFieldController() {
    super.dispose();
    userNameFieldController.dispose();
    deviceNameFieldController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Register New User"),
        centerTitle: true,
      ),
      body: Center(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device name input field.
              Padding(
                padding: const EdgeInsets.only(left: 400, right: 400),
                child: TextFormField(
                  controller: deviceNameFieldController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter A Device Name';
                    } else {
                      return null;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    prefixIcon: Icon(Icons.devices_sharp),
                    prefixIconColor: Colors.green,
                    border: OutlineInputBorder()
                  ),
                ),
              ),
              
              if(widget.devices.isNotEmpty)...{
                Padding(
                  padding: const EdgeInsets.only(left: 450, right: 450, top: 50),
                  
                  child: DropdownButtonFormField(
                    //value: selectedValue,
                    iconSize: 50.0,
                    iconEnabledColor: Colors.green,
                    items: widget.devices.map((dynamic selectedValue) {
                      return DropdownMenuItem<dynamic>(
                        value: selectedValue,
                        child: Text(selectedValue),
                      );
                    }).toList(),
                    // items: const [
                    //   DropdownMenuItem(child: Text("Windows"), value: "Windows"),
                    //   DropdownMenuItem(child: Text("IOS"), value: "IOS"),
                    //   DropdownMenuItem(child: Text("Android"), value: "Android"),
                    // ],
                    onChanged: (newValue) => {
                      setState(() {
                        selectedValue = newValue;
                      },)
                    },
                  ),
                ),
              },
              
              Padding(
                padding: const EdgeInsets.only(left: 0, right: 0, top: 50),
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final deviceNameValue = deviceNameFieldController.text;

                      if (widget.devices.isEmpty) {
                        KeyUtils.getClientKeys().then((keyPair) {
                          AuthUtils.registerNewDevice(widget.userName, deviceNameValue, keyPair.publicKey as RSAPublicKey).then((_) {
                            User.setUserData(widget.userName, deviceNameValue);
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                          });
                        });
                      } else {
                        // Do process for registering new device.
                      }
                    }
                  }, 
                  child: const Text('Register User')
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}