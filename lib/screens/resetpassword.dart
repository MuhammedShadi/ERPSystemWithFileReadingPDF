import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/providers/users_provider.dart';

UsersProvider _usersProvider = new UsersProvider();

class ReSetPassWord extends StatefulWidget {
  static const routeName = '/resetPassword';
  @override
  _ReSetPassWordState createState() => _ReSetPassWordState();
}

class _ReSetPassWordState extends State<ReSetPassWord> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String name = '';
  userName() async {
    name = await ShPrefs.instance.getStringValue('userName');
    setState(() {});
    print(name);
    return name;
  }

  @override
  void initState() {
    userName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (name == '') {
      userName();
    }
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: 210,
          child: new Text(
            'تغيير كلمة المرور ',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 20, fontFamily: 'Jazeera'),
          ),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/discussionsManagement', (Route<dynamic> route) => false);
            }),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Directionality(
                textDirection: ui.TextDirection.rtl,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _oldPasswordController,
                        cursorColor: Theme.of(context).colorScheme.secondary,
                        // initialValue: 'إترك تعليقك هنا',
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور القديمة',
                          labelStyle: TextStyle(
                            color: Color(0xFF6200EE),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF6200EE)),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _newPasswordController,
                        cursorColor: Theme.of(context).colorScheme.secondary,
                        // initialValue: 'إترك تعليقك هنا',
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور الجديدة',
                          labelStyle: TextStyle(
                            color: Color(0xFF6200EE),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF6200EE)),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // ignore: deprecated_member_use
                          FlatButton(
                            onPressed: () async {
                              if (_newPasswordController.text.isEmpty) {
                                Fluttertoast.showToast(
                                    msg: "لا يمكن تعديل كلمة مرور فارغة",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                    fontSize: 16.0);
                              } else {
                                if (await _usersProvider.updateUserPassword(
                                    name, _newPasswordController.text,
                                    oldPassword: _oldPasswordController.text)) {
                                  clearValues();
                                  Navigator.pop(context);
                                  // Navigator.of(context).pushReplacementNamed("/userManagement");
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/discussionsManagement',
                                      (Route<dynamic> route) => false);
                                }
                              }
                            },
                            child: Text(
                              "تغيير",
                              style: TextStyle(
                                  fontFamily: 'Jazeera',
                                  color: Colors.white,
                                  fontSize: 15),
                            ),
                            color: Colors.green,
                          ),
                          SizedBox(width: 10),
                          // ignore: deprecated_member_use
                          FlatButton(
                            onPressed: () {
                              setState(() {
                                clearValues();
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/discussionsManagement',
                                    (Route<dynamic> route) => false);
                              });
                            },
                            child: Text(
                              "إلغاء",
                              style: TextStyle(
                                  fontFamily: 'Jazeera',
                                  color: Colors.white,
                                  fontSize: 15),
                            ),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }

  clearValues() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
  }
}
