import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/providers/users_provider.dart';
import 'package:pdfviewer/screens/users_management.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

UsersProvider _usersProvider = new UsersProvider();
ScrollController _scrollController = ScrollController();
String userImage = 'assets/images/user.png';
String userName;
String userEmail;
List<dynamic> userDepartment = [];
List<dynamic> userHierarchy = [];
List<dynamic> depValue = [];
String userAccountType = '';

class UserDetails extends StatefulWidget {
  static const routName = '/userItemDetails';
  final String _userItem;
  UserDetails(this._userItem);
  @override
  _UserDetailsState createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  bool themeSwitched = false;
  bool hasModifyUsersPermission = true;
  bool hasViewsUsersPermission = true;
  bool hasDeleteUsersPermission = true;
  bool hasResetPUsersPasswordPermission = false;
  dynamic themeColor() {
    if (themeSwitched) {
      return Colors.grey[850];
    } else {}
  }

  Future<void> secureScreen() async {
    //print('secureScreen');
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void checkModifyUsersPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    //print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermission.contains("modify-own-user-info")) {
      // print(userPermission.contains("modify-any-user-info"));
      hasModifyUsersPermission = true;
    } else {
      hasModifyUsersPermission = false;
    }
  }

  void checkViewUsersPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    // print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermission.contains("view-own-user")) {
      // print(userPermission.contains("view-any-user"));
      hasViewsUsersPermission = true;
    } else {
      hasViewsUsersPermission = false;
    }
  }

  void checkDeleteUsersPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    // print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermission.contains("deactivate-own-user")) {
      // print(userPermission.contains("view-any-user"));
      hasDeleteUsersPermission = true;
    } else {
      hasDeleteUsersPermission = false;
    }
  }

  void checkResetUsersPasswordPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    // print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermission.contains("reset-own-user-password")) {
      hasResetPUsersPasswordPermission = true;
    } else {
      hasResetPUsersPasswordPermission = false;
    }
  }

  @override
  void initState() {
    secureScreen();
    super.initState();
  }

  String organizationName;
  List<String> departmentsValues = [];

  void buildDepartment(String userToEditOrganization) async {
    organizationName = await ShPrefs.instance.getStringValue("organization");
    departmentsValues =
        await _usersProvider.getOrganizationDepartments(userToEditOrganization);
    //
    // print(departmentsValues);
  }

  @override
  Widget build(BuildContext context) {
    checkModifyUsersPermissions();
    checkDeleteUsersPermissions();
    checkResetUsersPasswordPermissions();
    //buildDepartment();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        // ignore: deprecated_member_use
        brightness: themeSwitched ? Brightness.light : Brightness.dark,
        backgroundColor: themeColor(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'عرض بيانات المُستخدم',
                style: TextStyle(
                  fontFamily: 'Lalezar',
                  fontSize: 25,
                ),
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                IconButton(
                  icon: themeSwitched
                      ? Icon(Icons.wb_sunny,
                          color: themeSwitched ? Colors.white : Colors.black)
                      : Icon(
                          Icons.brightness_3,
                          color: themeSwitched ? Colors.white : Colors.black,
                        ),
                  onPressed: () {
                    setState(() {
                      themeSwitched = !themeSwitched;
                    });
                  },
                ),
                Positioned(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Navigator.of(context).pushReplacementNamed("/userManagement");
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/userManagement', (Route<dynamic> route) => false);
            }),
      ),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: getUser(widget._userItem),
    );
  }

  changePassword(context) async {
    final TextEditingController _oldPasswordController =
        TextEditingController();
    final TextEditingController _newPasswordController =
        TextEditingController();
    clearValues() {
      _oldPasswordController.clear();
      _newPasswordController.clear();
    }

    Alert(
      context: context,
      title: " تغيير كلمة المرور ${widget._userItem}",
      style: AlertStyle(
        titleStyle: TextStyle(
          color: Colors.indigo,
          fontFamily: 'Jazeera',
          fontSize: 20,
        ),
      ),
      content: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // TextFormField(
                //   controller: _oldPasswordController,
                //   cursorColor: Theme.of(context).colorScheme.secondary,
                //   // initialValue: 'إترك تعليقك هنا',
                //   decoration: InputDecoration(
                //     labelText: 'كلمة المرور القديمة',
                //     labelStyle: TextStyle(
                //       color: Color(0xFF6200EE),
                //     ),
                //     enabledBorder: UnderlineInputBorder(
                //       borderSide: BorderSide(color: Color(0xFF6200EE)),
                //     ),
                //   ),
                // ),
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
              ],
            ),
          )),
      buttons: [
        DialogButton(
          onPressed: () {
            setState(() {
              Navigator.pop(context);
            });
          },
          child: Text(
            "إلغاء",
            style: TextStyle(
                fontFamily: 'Jazeera', color: Colors.white, fontSize: 12),
          ),
          color: Colors.red,
        ),
        DialogButton(
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
                  widget._userItem, _newPasswordController.text)) {
                clearValues();
                Navigator.pop(context);
                // Navigator.of(context).pushReplacementNamed("/userManagement");
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/userManagement', (Route<dynamic> route) => false);
              }
            }
          },
          child: Text(
            "تغيير",
            style: TextStyle(
                fontFamily: 'Jazeera', color: Colors.white, fontSize: 12),
          ),
          color: Colors.green,
        ),
      ],
    ).show();
  }

  Widget getUser(String userName) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        color: Colors.black12,
        child: FutureBuilder<Map>(
          future: _usersProvider.getUserDetails(userName),
          builder: (BuildContext context, snapshot) {
            // print(snapshot.data);
            if (snapshot.data == null) {
              return Container(
                child: Padding(
                  padding: const EdgeInsets.only(left: 80, top: 0),
                  child: Center(
                    child: Row(
                      children: <Widget>[
                        Center(
                          child: Row(
                            children: <Widget>[
                              CircularProgressIndicator(),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Center(
                          child: Text(
                            "... من فضلك إنتظر يتم التحميل",
                            style: TextStyle(
                              fontFamily: 'Jazeera',
                              fontSize: 15,
                              color: themeSwitched ? Colors.white : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.none) {
              return Container(
                child: Padding(
                  padding: const EdgeInsets.only(left: 80, top: 0),
                  child: Center(
                    child: Row(
                      children: <Widget>[
                        Center(
                          child: Row(
                            children: <Widget>[
                              CircularProgressIndicator(),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Center(
                          child: Text(
                            "..لا توجد بيانات للعرض نتيجة البحث ",
                            style: TextStyle(
                              fontFamily: 'Jazeera',
                              fontSize: 15,
                              color: themeSwitched ? Colors.white : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // print(snapshot.data);
              userName = snapshot.data['name'];
              userEmail = snapshot.data['email'];
              userDepartment = snapshot.data['departments'];
              userHierarchy = snapshot.data['hierarchy'];
              userAccountType = snapshot.data['account_type'];
              buildDepartment(snapshot.data['organization']);
              //print(userDepartment);
              //print(userHierarchy);
              return Scrollbar(
                controller: _scrollController,
                child: Column(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  gradient: LinearGradient(
                                    colors: themeSwitched
                                        ? [Colors.white24, Colors.white10]
                                        : [Colors.black87, Colors.redAccent],
                                    begin: Alignment.centerRight,
                                    end: Alignment(-1.0, -1.0),
                                  ), //Gradient
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          child: Image.asset(
                                            userImage,
                                            height: 120,
                                            width: 120,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Container(
                                            child: Text(
                                              snapshot.data["name"],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24.0,
                                                fontFamily: 'Lato',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          child: Text(
                                            snapshot.data["email"],
                                            style: TextStyle(
                                              fontFamily: 'Lato',
                                              color: Colors.white,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          child: Text(
                                            snapshot.data["organization"],
                                            style: TextStyle(
                                              fontFamily: 'Lato-Bold',
                                              color: Colors.white,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          child: Text(
                                            snapshot.data["account_type"],
                                            style: TextStyle(
                                              fontFamily: 'Lato-Regular',
                                              color: Colors.white,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              hasModifyUsersPermission
                                  ? Positioned(
                                      left: 0.0,
                                      bottom: 0.0,
                                      height: 40,
                                      width: 40,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                          size: 30,
                                        ),
                                        onPressed: () {
                                          updateDataUser(context);
                                        },
                                      ),
                                    )
                                  : Row(),
                              hasDeleteUsersPermission
                                  ? Positioned(
                                      right: 0.0,
                                      bottom: 0.0,
                                      height: 40,
                                      width: 40,
                                      child: snapshot.data['active'] == true
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                              onPressed: () async {
                                                print(
                                                    snapshot.data['username']);
                                                Alert(
                                                  context: context,
                                                  title:
                                                      " هل أنت متأكد من تعطيل الحساب ؟",
                                                  style: AlertStyle(
                                                    titleStyle: TextStyle(
                                                      color: Colors.indigo,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                  content: Row(),
                                                  buttons: [
                                                    DialogButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          Navigator.pop(
                                                              context);
                                                        });
                                                      },
                                                      child: Text(
                                                        "لا",
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Jazeera',
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                      color: Colors.blueGrey,
                                                    ),
                                                    DialogButton(
                                                      onPressed: () {
                                                        _usersProvider
                                                            .deActiveAccount(
                                                                snapshot.data[
                                                                    'username']);

                                                        Navigator.push(
                                                          context,
                                                          new MaterialPageRoute(
                                                              builder: (context) =>
                                                                  UserManagement()),
                                                        );
                                                      },
                                                      child: Text(
                                                        "نعم",
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Jazeera',
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                      color: Colors.red,
                                                    ),
                                                  ],
                                                ).show();
                                              })
                                          : IconButton(
                                              icon: Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                Alert(
                                                  context: context,
                                                  title:
                                                      " هل أنت متأكد من تفعيل الحساب ؟",
                                                  style: AlertStyle(
                                                    titleStyle: TextStyle(
                                                      color: Colors.indigo,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                  content: Row(),
                                                  buttons: [
                                                    DialogButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          Navigator.pop(
                                                              context);
                                                        });
                                                      },
                                                      child: Text(
                                                        "لا",
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Jazeera',
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                      color: Colors.blueGrey,
                                                    ),
                                                    DialogButton(
                                                      onPressed: () {
                                                        print(snapshot
                                                            .data['username']);
                                                        _usersProvider
                                                            .reActiveAccount(
                                                                snapshot.data[
                                                                    'username']);
                                                        Navigator.push(
                                                          context,
                                                          new MaterialPageRoute(
                                                              builder: (context) =>
                                                                  UserManagement()),
                                                        );
                                                      },
                                                      child: Text(
                                                        "نعم",
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Jazeera',
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                      color: Colors.green,
                                                    ),
                                                  ],
                                                ).show();
                                              },
                                            ),
                                    )
                                  : Row(),
                              hasResetPUsersPasswordPermission == true
                                  ? Positioned(
                                      left: 0.0,
                                      top: 0.0,
                                      height: 40,
                                      width: 40,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.vpn_key,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        onPressed: () {
                                          changePassword(context);
                                        },
                                      ),
                                    )
                                  : Row(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  updateDataUser(context) async {
    final TextEditingController _userNameController =
        TextEditingController(text: widget._userItem);
    final TextEditingController _userMailController =
        TextEditingController(text: userEmail);
    final TextEditingController _userHirarichyController =
        TextEditingController(
            text: userHierarchy
                .toString()
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll('[', ''));

    List departmentsOptions = [
      {"display": "default", "value": "default"}
    ];
    if (departmentsValues != null) {
      departmentsOptions = List.generate(
          departmentsValues.length,
          (index) => {
                "display": departmentsValues[index],
                "value": departmentsValues[index],
              });
    }
    clearUpdateDataValues() {
      _userNameController.clear();
      _userMailController.clear();
      _userHirarichyController.clear();
      userDepartment.clear();
      depValue.clear();
    }

    Alert(
      context: context,
      title: " تعديل بيانات المستخدم ",
      style: AlertStyle(
        titleStyle: TextStyle(
          color: Colors.red,
          fontFamily: 'Jazeera',
          fontSize: 20,
        ),
      ),
      content: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _userNameController,
                cursorColor: Theme.of(context).colorScheme.secondary,
                // initialValue: 'إترك تعليقك هنا',
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'الإسم',
                  labelStyle: TextStyle(
                    color: Color(0xFF6200EE),
                  ),
                  helperText: 'عدد الأحرف',
                  suffixIcon: Icon(
                    Icons.person_add,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6200EE)),
                  ),
                ),
              ),
              TextFormField(
                controller: _userMailController,
                cursorColor: Theme.of(context).colorScheme.secondary,
                validator: (value) {
                  if (value.isEmpty ||
                      value.contains('@') ||
                      value.contains('123')) {
                    return 'من فضلك أدخل بيانات صحيحة';
                  }
                  return null;
                },
                // initialValue: 'إترك تعليقك هنا',
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'بريد إلكتروني',
                  labelStyle: TextStyle(
                    color: Color(0xFF6200EE),
                  ),
                  helperText: 'عدد الأحرف',
                  suffixIcon: Icon(
                    Icons.mail,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6200EE)),
                  ),
                ),
              ),
              userAccountType == 'regular-user'
                  ? MultiSelectFormField(
                      chipBackGroundColor: Colors.red,
                      chipLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                      dialogTextStyle: TextStyle(fontWeight: FontWeight.bold),
                      checkBoxActiveColor: Colors.red,
                      checkBoxCheckColor: Colors.white,
                      dialogShapeBorder: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(12.0))),
                      title: Text(
                        "الأقسام",
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Jazeera',
                          fontSize: 15,
                        ),
                      ),
                      dataSource: departmentsOptions,
                      textField: 'display',
                      valueField: 'value',
                      okButtonLabel: 'تم',
                      cancelButtonLabel: 'إلغاء',
                      hintWidget: Text(
                        userDepartment
                                    .toString()
                                    .replaceAll('[', '')
                                    .replaceAll(']', '') ==
                                ''
                            ? 'لا يوجد اقسام'
                            : userDepartment
                                .toString()
                                .replaceAll('[', '')
                                .replaceAll(']', ''),
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Jazeera',
                          fontSize: 10,
                        ),
                      ),
                      initialValue: depValue,
                      onSaved: (value) {
                        if (value == null) return;
                        setState(() {
                          depValue = value;
                          print(depValue);
                        });
                      },
                    )
                  : Row(),
              userAccountType == 'organization'
                  ? TextFormField(
                      controller: _userHirarichyController,
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      decoration: InputDecoration(
                        hintText: "e.g 1,2,3;4,5",
                        labelText: 'الهيكلة',
                        labelStyle: TextStyle(
                          color: Color(0xFF6200EE),
                        ),
                        helperText: 'e.g 1,2,3;4,5',
                        suffixIcon: Icon(
                          Icons.person_add,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6200EE)),
                        ),
                      ),
                      onChanged: (text) {
                        text = _userHirarichyController.text;
                        print(text);
                      },
                    )
                  : Row(),
            ],
          ),
        ),
      ),
      buttons: [
        DialogButton(
          onPressed: () {
            clearUpdateDataValues();
            setState(() {
              Navigator.pop(context);
            });
          },
          child: Text(
            "إلغاء",
            style: TextStyle(
                fontFamily: 'Jazeera', color: Colors.white, fontSize: 12),
          ),
          color: Colors.red,
        ),
        DialogButton(
          onPressed: () async {
            var userNameText = _userNameController.text;
            var userMailText = _userMailController.text;
            var userHiraText = _userHirarichyController.text;
            print(userNameText);
            print(userMailText);
            print(depValue);
            print(userHiraText);
            if (userNameText.isEmpty || userMailText.isEmpty) {
              Fluttertoast.showToast(
                  msg: "لا يمكن إضافة تعديل فارغ",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            } else {
              print('TestHere');
              List orgLevels = userHiraText.split(';');
              // print('orgLevels0: ' + orgLevels[0]);
              // print('orgLevels1: ' + orgLevels[1]);
              List<List<String>> fullHira2 = [];
              for (var i in orgLevels) {
                print('orgLevels[i]: ' + i);
                List<String> departementsLevel = i.toString().split(',');
                print('departementsLevel: ' + departementsLevel.toString());
                fullHira2.add(departementsLevel);
              }

              bool editUser = await _usersProvider.updateUserDetails(
                  userAccountType,
                  widget._userItem,
                  userNameText,
                  userMailText,
                  depValue,
                  fullHira2);
              if (editUser == true) {
                setState(() {
                  _usersProvider.updateUserDetails(
                      userAccountType,
                      widget._userItem,
                      userNameText,
                      userMailText,
                      depValue,
                      fullHira2);
                  clearUpdateDataValues();
                  Navigator.pop(context);
                });
              }
            }
          },
          child: Text(
            "أرسل",
            style: TextStyle(
                fontFamily: 'Jazeera', color: Colors.white, fontSize: 12),
          ),
          color: Colors.green,
        ),
      ],
    ).show();
  }
}
