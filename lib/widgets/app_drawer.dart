import 'package:flutter/material.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';

LoginProvider _loginProvider = new LoginProvider();

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

String userPermissions = '';

class _AppDrawerState extends State<AppDrawer> {
  bool checkViewOnUser = false;
  String name = '';
  var isSwitched = false;

  userName() async {
    name = await ShPrefs.instance.getStringValue("userName");
    setState(() {});
    return name;
  }

  void isSwitchedValue() async {
    //
    isSwitched = (await ShPrefs.instance.getStringValue("isSwitched") != null ||
            await ShPrefs.instance.getStringValue("isSwitched") != "")
        ? toBoolean(await ShPrefs.instance.getStringValue("isSwitched"))
        : false;
    ShPrefs.instance.setStringValue('isSwitched', isSwitched.toString());
  }

  bool toBoolean(String str, [bool strict]) {
    if (strict == true) {
      return str == 'true';
    }
    return str != 'false' && str != '';
  }

  void checkViewOwnUserPermissions() async {
    userPermissions = await ShPrefs.instance.getStringValue("permissions");
    if (userPermissions.contains('view-own-user')) {
      checkViewOnUser = true;
    } else {
      checkViewOnUser = false;
    }
  }

  @override
  void initState() {
    checkViewOwnUserPermissions();
    userName();
    isSwitchedValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (userPermissions == '' && userPermissions.isNotEmpty) {
      checkViewOwnUserPermissions();
      userName();
      isSwitchedValue();
    }
    return Drawer(
      child: Container(
        child: Column(
          children: <Widget>[
            AppBar(
              title: Row(
                children: [
                  SizedBox(
                    width: 35,
                  ),
                  Center(
                    child: SizedBox(
                      child: Text(
                        ' $name مرحباً بك '.toUpperCase(),
                        style: TextStyle(
                            fontFamily: 'Jazeera',
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Switch(
                    value: isSwitched,
                    onChanged: (value) async {
                      setState(() {
                        isSwitched = value;
                        ShPrefs.instance.setStringValue(
                            'isSwitched', isSwitched.toString());
                        print(isSwitched);
                      });
                      print(
                          await ShPrefs.instance.getStringValue('isSwitched'));
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              automaticallyImplyLeading: false,
            ),
            InkWell(
              child: SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height - 90,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.home,
                          color: Colors.red,
                        ),
                        title: Text(
                          'الرئيسية',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            color: Colors.black,
                          ),
                        ),
                        onTap: () {
                          // Navigator.of(context)
                          //     .pushReplacementNamed(HomeScreen.routName);
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/HomeScreen', (Route<dynamic> route) => false);
                        },
                      ),
                      checkViewOnUser
                          ? ListTile(
                              leading: Icon(
                                Icons.person,
                                color: Colors.red,
                              ),
                              title: Text(
                                'إدارة المُستخدم',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Jazeera',
                                  color: Colors.black,
                                ),
                              ),
                              onTap: () {
                                // Navigator.of(context).pushReplacementNamed(
                                //     UserManagement.routName);
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/userManagement',
                                    (Route<dynamic> route) => false);
                              },
                            )
                          : Row(),
                      ListTile(
                        leading: Icon(
                          Icons.wysiwyg,
                          color: Colors.red,
                        ),
                        title: Text(
                          'إدارة المناقشات',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            color: Colors.black,
                          ),
                        ),
                        onTap: () {
                          // Navigator.of(context).pushReplacementNamed(
                          //     DiscussionsManagement.routName);
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/discussionsManagement',
                              (Route<dynamic> route) => false);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.messenger_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          'إدارة الرسائل',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            color: Colors.black,
                          ),
                        ),
                        onTap: () {
                          // Navigator.of(context).pushReplacementNamed(
                          //     DiscussionsManagement.routName);
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/messagesManagement',
                              (Route<dynamic> route) => false);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.vpn_key,
                          color: Colors.red,
                        ),
                        title: Text(
                          'تغيير كلمة المرور',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            color: Colors.black,
                          ),
                        ),
                        onTap: () {
                          // Navigator.of(context).pushReplacementNamed(
                          //     UserManagement.routName);
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/resetPassword',
                              (Route<dynamic> route) => false);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        title: Text(
                          'تسجيل خروج',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            color: Colors.black,
                          ),
                        ),
                        onTap: () {
                          _loginProvider.logOut();
                          setState(() {});
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/HomeScreen', (Route<dynamic> route) => false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
