import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:pagination_view/pagination_view.dart';
import 'package:pdfviewer/models/new_user.dart';
import 'package:pdfviewer/models/user_item.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/providers/users_provider.dart';
import 'package:pdfviewer/screens/user_details.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

UsersProvider _usersProvider = new UsersProvider();
double offset = 0.0;

bool themeSwitched = false;
String userPermissions = '';
bool hasCreateOrganization = true;
bool accountTypeOrg = true;
dynamic themeColor() {
  if (themeSwitched) {
    return Colors.grey[850];
  } else {}
}

class UserManagement extends StatefulWidget {
  static const routName = '/userManagement';
  @override
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool hasCreateUserPermission = true;
  bool hasViewsUsersPermission = true;

  String userAccountPermission = '';
  int page;
  PaginationViewType paginationViewType;
  GlobalKey<PaginationViewState> key;

  Future<void> secureScreen() async {
    //print('secureScreen');
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void checkCreateUserPermissions() async {
    userPermissions = await ShPrefs.instance.getStringValue("permissions");
    // print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermissions.contains("create-user")) {
      // print(userPermission.contains("create-user"));
      hasCreateUserPermission = true;
    } else {
      hasCreateUserPermission = false;
    }
    setState(() {});
  }

  void checkCreateOrganizationPermissions() async {
    userPermissions = await ShPrefs.instance.getStringValue("permissions");
    // print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermissions.contains("create-organization")) {
      // print(userPermission.contains("create-user"));
      hasCreateOrganization = true;
    } else {
      hasCreateOrganization = false;
    }
    setState(() {});
  }

  void checkViewUsersPermissions() async {
    userPermissions = await ShPrefs.instance.getStringValue("permissions");
    // print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermissions.contains("view-own-user")) {
      hasViewsUsersPermission = true;
    } else {
      hasViewsUsersPermission = false;
    }
    setState(() {});
  }

  @override
  void initState() {
    secureScreen();
    checkCreateUserPermissions();
    checkViewUsersPermissions();
    checkCreateOrganizationPermissions();
    super.initState();
    page = 0;
    paginationViewType = PaginationViewType.listView;
    key = GlobalKey<PaginationViewState>();
  }

  @override
  Widget build(BuildContext context) {
    if (userPermissions == '') {
      checkCreateUserPermissions();
      checkViewUsersPermissions();
      checkCreateOrganizationPermissions();
    }
    buildDepartment();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        // ignore: deprecated_member_use
        brightness: themeSwitched ? Brightness.light : Brightness.dark,
        backgroundColor: themeColor(),
        title: Row(
          children: [
            Center(
              child: Text(
                "إدارة المُستخدم",
                style: TextStyle(
                  fontFamily: 'Jazeera',
                  fontSize: 19,
                ),
              ),
            ),
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
            (paginationViewType == PaginationViewType.listView)
                ? IconButton(
                    icon: Icon(Icons.grid_on),
                    onPressed: () => setState(
                        () => paginationViewType = PaginationViewType.gridView),
                  )
                : IconButton(
                    icon: Icon(Icons.list),
                    onPressed: () => setState(
                        () => paginationViewType = PaginationViewType.listView),
                  ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => key.currentState.refresh(),
            ),
          ],
        ),
        leading: hasCreateUserPermission == true
            ? IconButton(
                icon: Icon(
                  Icons.person_add,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(builder: (context) => AddNewUser()),
                  );
                })
            : Row(),
      ),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: hasViewsUsersPermission
          ? getUsersData()
          : Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ليس لديك صلاحيات",
                    style: TextStyle(
                      fontFamily: 'Jazeera',
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 300.0),
        child: FloatingActionButton(
          onPressed: () {
            getFilteredData(context);
          },
          tooltip: 'Search',
          child: Icon(Icons.filter_list),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget getUsersData() {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        color: Colors.black12,
        child: PaginationView<UserItem>(
          key: key,
          paginationViewType: paginationViewType,
          itemBuilder: (BuildContext context, UserItem user, int index) =>
              (paginationViewType == PaginationViewType.listView)
                  ? Card(
                      color: themeColor(),
                      margin: const EdgeInsets.only(
                          left: 5.0, right: 5.0, bottom: 10.0, top: 3.0),
                      elevation: 4.0,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                new MaterialPageRoute(
                                    builder: (context) =>
                                        UserDetails(user.username)),
                              );
                            },
                            child: Row(
                              children: <Widget>[
                                user.accountType == 'organization'
                                    ? Stack(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 40,
                                            color: themeSwitched
                                                ? Colors.white
                                                : Colors.red,
                                          ),
                                          Positioned(
                                            bottom: 0.0,
                                            right: 0.0,
                                            child: Material(
                                              // eye button (customised radius)
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(5.0),
                                                topRight: Radius.circular(5.0),
                                                bottomRight:
                                                    Radius.circular(5.0),
                                                bottomLeft:
                                                    Radius.circular(5.0),
                                              ),

                                              child: user.active == true
                                                  ? Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 18,
                                                    )
                                                  : Icon(
                                                      Icons.cancel_outlined,
                                                      color: Colors.red,
                                                      size: 18,
                                                    ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : user.accountType == 'regular-user'
                                        ? Stack(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                size: 40,
                                                color: themeSwitched
                                                    ? Colors.white
                                                    : Colors.blueAccent,
                                              ),
                                              Positioned(
                                                bottom: 0.0,
                                                right: 0.0,
                                                child: Material(
                                                  // eye button (customised radius)
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(5.0),
                                                    topRight:
                                                        Radius.circular(5.0),
                                                    bottomRight:
                                                        Radius.circular(5.0),
                                                    bottomLeft:
                                                        Radius.circular(5.0),
                                                  ),

                                                  child: user.active == true
                                                      ? Icon(
                                                          Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 18,
                                                        )
                                                      : Icon(
                                                          Icons.cancel_outlined,
                                                          color: Colors.red,
                                                          size: 18,
                                                        ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4),
                                              child: Text(
                                                user.name,
                                                style: new TextStyle(
                                                  color: themeSwitched
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontFamily: 'Jazeera',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: Text(
                                                user.username,
                                                style: new TextStyle(
                                                  color: themeSwitched
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontFamily: 'Jazeera',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              child: Text(
                                                user.email,
                                                style: new TextStyle(
                                                  color: themeSwitched
                                                      ? Colors.white24
                                                      : Colors.black26,
                                                  fontFamily: 'Jazeera',
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Container(
                                                child: user.seenAt == null
                                                    ? Text(
                                                        'Didn\'t Loged In Yet ..! ',
                                                        style: new TextStyle(
                                                          color: themeSwitched
                                                              ? Colors.white24
                                                              : Colors.black26,
                                                          fontFamily: 'Jazeera',
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.end,
                                                      )
                                                    : Text(
                                                        user.seenAt
                                                                .split('T')[0] +
                                                            ' ' +
                                                            user.seenAt
                                                                .split('T')[1]
                                                                .split('.')[0],
                                                        style: new TextStyle(
                                                          color: themeSwitched
                                                              ? Colors.white24
                                                              : Colors.black26,
                                                          fontFamily: 'Jazeera',
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.end,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      color: themeColor(),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) =>
                                    UserDetails(user.username)),
                          );
                        },
                        child: GridTile(
                          child: Container(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          user.accountType == 'organization'
                                              ? Stack(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 40,
                                                      color: themeSwitched
                                                          ? Colors.white
                                                          : Colors.red,
                                                    ),
                                                    Positioned(
                                                      bottom: 0.0,
                                                      right: 0.0,
                                                      child: Material(
                                                        // eye button (customised radius)
                                                        borderRadius:
                                                            BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  5.0),
                                                          topRight:
                                                              Radius.circular(
                                                                  5.0),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  5.0),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  5.0),
                                                        ),

                                                        child: user.active ==
                                                                true
                                                            ? Icon(
                                                                Icons
                                                                    .check_circle,
                                                                color: Colors
                                                                    .green,
                                                                size: 18,
                                                              )
                                                            : Icon(
                                                                Icons
                                                                    .cancel_outlined,
                                                                color:
                                                                    Colors.red,
                                                                size: 18,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : user.accountType ==
                                                      'regular-user'
                                                  ? Stack(
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          size: 40,
                                                          color: themeSwitched
                                                              ? Colors.white
                                                              : Colors
                                                                  .blueAccent,
                                                        ),
                                                        Positioned(
                                                          bottom: 0.0,
                                                          right: 0.0,
                                                          child: Material(
                                                            // eye button (customised radius)
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topLeft: Radius
                                                                  .circular(
                                                                      5.0),
                                                              topRight: Radius
                                                                  .circular(
                                                                      5.0),
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          5.0),
                                                              bottomLeft: Radius
                                                                  .circular(
                                                                      5.0),
                                                            ),

                                                            child:
                                                                user.active ==
                                                                        true
                                                                    ? Icon(
                                                                        Icons
                                                                            .check_circle,
                                                                        color: Colors
                                                                            .green,
                                                                        size:
                                                                            18,
                                                                      )
                                                                    : Icon(
                                                                        Icons
                                                                            .cancel_outlined,
                                                                        color: Colors
                                                                            .red,
                                                                        size:
                                                                            18,
                                                                      ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Row(),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Container(
                                                child: Text(
                                                  user.name,
                                                  style: new TextStyle(
                                                    color: themeSwitched
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontFamily: 'Jazeera',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Container(
                                                child: Text(
                                                  user.email,
                                                  style: new TextStyle(
                                                    color: themeSwitched
                                                        ? Colors.white24
                                                        : Colors.black26,
                                                    fontFamily: 'Jazeera',
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      user.seenAt == null
                                          ? Row()
                                          : Row(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: Container(
                                                      child: Text(
                                                        user.seenAt
                                                                .split('T')[0] +
                                                            ' ' +
                                                            user.seenAt
                                                                .split('T')[1]
                                                                .split('.')[0],
                                                        style: new TextStyle(
                                                          color: themeSwitched
                                                              ? Colors.white24
                                                              : Colors.black26,
                                                          fontFamily: 'Jazeera',
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
          shrinkWrap: true,
          pageFetch: pageFetch,
          //pageRefresh: pageRefresh,
          pullToRefresh: true,
          onError: (dynamic error) => Center(
            child: Text('Some error occured'),
          ),
          onEmpty: Center(
            child: Text('Sorry! This is empty'),
          ),
          bottomLoader: Center(
            child: CircularProgressIndicator(),
          ),
          initialLoader: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  getFilteredData(context) async {
    final TextEditingController _nameFilteredController =
        TextEditingController();
    final TextEditingController _userNameFilteredController =
        TextEditingController();
    final TextEditingController _userOrgFilteredController =
        TextEditingController();
    List departmentsOptions = List.generate(
        departmentsValues.length,
        (index) => {
              "display": departmentsValues[index],
              "value": departmentsValues[index]
            });

    List accountTypeValues = [
      {
        "display": "مؤسسة",
        "value": "organization",
      },
      {
        "display": "مستخدم عادي",
        "value": "regular-user",
      },
    ];
    List accountTypeStatus = [
      {
        "display": "مُفعل",
        "value": "true",
      },
      {
        "display": "غير مُفعل",
        "value": "false",
      },
    ];
    List<dynamic> accountValue = [];
    List<dynamic> accountStatue = [];
    List<dynamic> depValue = [];
    String depParam = '';
    String accountTypeParam = '';
    String accountStatueParam = '';
    filteredValues() {
      for (int i = 0; i < depValue.length; i++) {
        depParam += "&departments=${Uri.encodeFull(depValue[i].toString())}";
      }
      for (int i = 0; i < accountValue.length; i++) {
        accountTypeParam +=
            "&account_type=${Uri.encodeFull(accountValue[i].toString())}";
      }
      for (int i = 0; i < accountStatue.length; i++) {
        accountStatueParam +=
            "&active=${Uri.encodeFull(accountStatue[i].toString())}";
      }
      ShPrefs.instance.setStringValue('department', depParam);
      ShPrefs.instance.setStringValue('accountTypes', accountTypeParam);
      ShPrefs.instance.setStringValue('accountStatues', accountStatueParam);
      ShPrefs.instance.setStringValue('names', _nameFilteredController.text);
      ShPrefs.instance
          .setStringValue('usernames', _userNameFilteredController.text);
      ShPrefs.instance
          .setStringValue('organizations', _userOrgFilteredController.text);
    }

    clearValues() {
      _nameFilteredController.clear();
      _userNameFilteredController.clear();
      _userOrgFilteredController.clear();
      depValue = [];
      accountValue = [];
    }

    removeValues() {
      ShPrefs.instance.removeValue('department');
      ShPrefs.instance.removeValue('accountTypes');
      ShPrefs.instance.removeValue('accountStatues');
      ShPrefs.instance.removeValue('names');
      ShPrefs.instance.removeValue('usernames');
      ShPrefs.instance.removeValue('organizations');
    }

    Alert(
      context: context,
      title: " بحث عن مستخدم",
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
                TextFormField(
                  controller: _nameFilteredController,
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
                  controller: _userNameFilteredController,
                  cursorColor: Theme.of(context).colorScheme.secondary,
                  // initialValue: 'إترك تعليقك هنا',
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'إسم مُستخدم',
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
                MultiSelectFormField(
                  autovalidate: AutovalidateMode.disabled,
                  chipBackGroundColor: Colors.red,
                  chipLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                  dialogTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  checkBoxActiveColor: Colors.red,
                  checkBoxCheckColor: Colors.white,
                  dialogShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
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
                    "إختر قسم أو أكثر",
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
                      //print(depValue);
                    });
                  },
                ),
                MultiSelectFormField(
                  autovalidate: AutovalidateMode.disabled,
                  chipBackGroundColor: Colors.red,
                  chipLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                  dialogTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  checkBoxActiveColor: Colors.red,
                  checkBoxCheckColor: Colors.white,
                  dialogShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  title: Text(
                    "نوع الحساب",
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Jazeera',
                      fontSize: 15,
                    ),
                  ),
                  dataSource: accountTypeValues,
                  textField: 'display',
                  valueField: 'value',
                  okButtonLabel: 'تم',
                  cancelButtonLabel: 'إلغاء',
                  hintWidget: Text(
                    "إختر نوع حساب",
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Jazeera',
                      fontSize: 10,
                    ),
                  ),
                  initialValue: accountValue,
                  onSaved: (value) {
                    if (value == null) return;
                    setState(() {
                      accountValue = value;
                      print(accountValue);
                    });
                  },
                ),
                MultiSelectFormField(
                  autovalidate: AutovalidateMode.disabled,
                  chipBackGroundColor: Colors.red,
                  chipLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                  dialogTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  checkBoxActiveColor: Colors.red,
                  checkBoxCheckColor: Colors.white,
                  dialogShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  title: Text(
                    "حالة الحساب",
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Jazeera',
                      fontSize: 15,
                    ),
                  ),
                  dataSource: accountTypeStatus,
                  textField: 'display',
                  valueField: 'value',
                  okButtonLabel: 'تم',
                  cancelButtonLabel: 'إلغاء',
                  hintWidget: Text(
                    "إختر نوع حساب",
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Jazeera',
                      fontSize: 10,
                    ),
                  ),
                  initialValue: accountStatue,
                  onSaved: (value) {
                    if (value == null) return;
                    setState(() {
                      accountStatue = value;
                      print(accountStatue);
                    });
                  },
                ),
                TextFormField(
                  controller: _userOrgFilteredController,
                  cursorColor: Theme.of(context).colorScheme.secondary,
                  // initialValue: 'إترك تعليقك هنا',
                  decoration: InputDecoration(
                    labelText: 'إسم المؤسسة',
                    labelStyle: TextStyle(
                      color: Color(0xFF6200EE),
                    ),
                    suffixIcon: Icon(
                      Icons.account_balance,
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
              removeValues();
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
          onPressed: () {
            setState(() {
              clearValues();
              removeValues();
              // Navigator.of(context).pushReplacementNamed("/userManagement");
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/userManagement', (Route<dynamic> route) => false);
            });
          },
          child: Text(
            "مسح الفلتر",
            style: TextStyle(
                fontFamily: 'Jazeera', color: Colors.white, fontSize: 12),
          ),
          color: Colors.blue,
        ),
        DialogButton(
          onPressed: () {
            setState(() {
              filteredValues();
              clearValues();
              Navigator.pop(context);
              // Navigator.of(context).pushReplacementNamed("/userManagement");
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/userManagement', (Route<dynamic> route) => false);
            });
          },
          child: Text(
            "بحث",
            style: TextStyle(
                fontFamily: 'Jazeera', color: Colors.white, fontSize: 12),
          ),
          color: Colors.green,
        ),
      ],
    ).show();
  }

  Future<List<UserItem>> pageFetch(int offset) async {
    page++;
    final List<UserItem> nextUsrList =
        await _usersProvider.getUsersP(pageNum: page);
    await Future<List<UserItem>>.delayed(Duration(milliseconds: 30));

    var maxPage = 0;

    String maxPageS = await ShPrefs.instance.getStringValue('usersPages');

    if (maxPageS != "") {
      maxPage = int.parse(maxPageS);
    }

    return page == maxPage + 1 ? [] : nextUsrList;
  }

  Future<List<UserItem>> pageRefresh(int offset) async {
    page = 0;
    return pageFetch(offset);
  }
}

String organizationName;
List<String> departmentsValues = [];

void buildDepartment() async {
  organizationName = await ShPrefs.instance.getStringValue("organization");
  departmentsValues =
      await _usersProvider.getOrganizationDepartments(organizationName);
  //
  // print(departmentsValues);
}

class AddNewUser extends StatefulWidget {
  @override
  _AddNewUserState createState() => _AddNewUserState();
}

class _AddNewUserState extends State<AddNewUser> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountTypeController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _userMailController = TextEditingController();
  final TextEditingController _userDepartmentsController =
      TextEditingController();
  final TextEditingController _userHierarchyController =
      TextEditingController();
  @override
  void initState() {
    buildDepartment();
    super.initState();
  }

  bool addResponse;
  List departmentsOptions = List.generate(
      departmentsValues.length,
      (index) => {
            "display": departmentsValues[index],
            "value": departmentsValues[index]
          });

  bool regularUserValue = true;
  bool organizationValue = true;
  List<dynamic> depValue = [];
  List<dynamic> depValue1 = [];
  List<dynamic> depValue2 = [];
  List<dynamic> depValue3 = [];
  List<dynamic> hValueTotal = [];

  List accountTypeValues = [
    {
      "display": "مؤسسة",
      "value": "organization",
    },
    {
      "display": "مدير مؤسسة",
      "value": "admin-user",
    },
    {
      "display": "مستخدم عادي",
      "value": "regular-user",
    },
  ];

  List accountTypeValuesNotSuper = [
    {
      "display": "مدير مؤسسة",
      "value": "admin-user",
    },
    {
      "display": "مستخدم عادي",
      "value": "regular-user",
    },
  ];

  List<dynamic> accountValue;
  @override
  Widget build(BuildContext context) {
    buildDepartment();
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
                  "إضافة مُستخدم جديد",
                  style: TextStyle(
                    fontFamily: 'Jazeera',
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
              icon: Icon(
                Icons.arrow_back,
              ),
              onPressed: () {
                // Navigator.of(context).pushReplacementNamed("/userManagement");
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/userManagement', (Route<dynamic> route) => false);
              })),
      endDrawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: themeColor(),
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
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
                          controller: _userNameController,
                          cursorColor: Theme.of(context).colorScheme.secondary,
                          // initialValue: 'إترك تعليقك هنا',
                          maxLength: 300,
                          decoration: InputDecoration(
                            labelText: 'إسم مُستخدم',
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
                          controller: _userPasswordController,
                          cursorColor: Theme.of(context).colorScheme.secondary,
                          // initialValue: 'إترك تعليقك هنا',
                          maxLength: 300,
                          decoration: InputDecoration(
                            labelText: 'كلمة مرور',
                            labelStyle: TextStyle(
                              color: Color(0xFF6200EE),
                            ),
                            helperText: 'عدد الأحرف',
                            suffixIcon: Icon(
                              Icons.remove_red_eye,
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
                        hasCreateOrganization
                            ? MultiSelectFormField(
                                required: true,
                                autovalidate: AutovalidateMode.disabled,
                                chipBackGroundColor: Colors.red,
                                chipLabelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                dialogTextStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                checkBoxActiveColor: Colors.red,
                                checkBoxCheckColor: Colors.white,
                                dialogShapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(12.0))),
                                title: Text(
                                  "نوع الحساب",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Jazeera',
                                    fontSize: 15,
                                  ),
                                ),
                                dataSource: accountTypeValues,
                                textField: 'display',
                                valueField: 'value',
                                okButtonLabel: 'تم',
                                cancelButtonLabel: 'إلغاء',
                                hintWidget: Text(
                                  "إختر نوع حساب",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Jazeera',
                                    fontSize: 10,
                                  ),
                                ),
                                initialValue: accountValue,
                                onSaved: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    accountValue = value;
                                    if (accountValue[0] == 'organization') {
                                      setState(() {
                                        regularUserValue = false;
                                        print(accountValue);
                                      });
                                    } else {
                                      setState(() {
                                        regularUserValue = true;
                                      });
                                    }
                                    if (accountValue[0] == 'regular-user') {
                                      setState(() {
                                        organizationValue = false;
                                        print(accountValue);
                                      });
                                    } else {
                                      setState(() {
                                        organizationValue = true;
                                      });
                                    }
                                    print(accountValue);
                                  });
                                },
                              )
                            : Row(),
                        organizationValue
                            ? Row()
                            : MultiSelectFormField(
                                autovalidate: AutovalidateMode.disabled,
                                chipBackGroundColor: Colors.red,
                                chipLabelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                dialogTextStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                checkBoxActiveColor: Colors.red,
                                checkBoxCheckColor: Colors.white,
                                dialogShapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(12.0))),
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
                                  "إختر قسم أو أكثر",
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
                              ),
                        regularUserValue
                            ? Row()
                            : TextFormField(
                                controller: _userHierarchyController,
                                cursorColor:
                                    Theme.of(context).colorScheme.secondary,
                                // initialValue: 'إترك تعليقك هنا',
                                decoration: InputDecoration(
                                  labelText: 'الهيكلة',
                                  // hintText: "e.g 1,2,3;4,5",
                                  labelStyle: TextStyle(
                                    color: Color(0xFF6200EE),
                                  ),
                                  helperText: 'e.g 1,2,3;4,5',
                                  suffixIcon: Icon(
                                    Icons.person_add,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFF6200EE)),
                                  ),
                                ),
                              ),
                        !hasCreateOrganization
                            ? Column(
                                children: [
                                  MultiSelectFormField(
                                    required: true,
                                    autovalidate: AutovalidateMode.disabled,
                                    chipBackGroundColor: Colors.red,
                                    chipLabelStyle:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    dialogTextStyle:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    checkBoxActiveColor: Colors.red,
                                    checkBoxCheckColor: Colors.white,
                                    dialogShapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12.0))),
                                    title: Text(
                                      "نوع الحساب",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontFamily: 'Jazeera',
                                        fontSize: 15,
                                      ),
                                    ),
                                    dataSource: accountTypeValuesNotSuper,
                                    textField: 'display',
                                    valueField: 'value',
                                    okButtonLabel: 'تم',
                                    cancelButtonLabel: 'إلغاء',
                                    hintWidget: Text(
                                      "إختر نوع حساب",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontFamily: 'Jazeera',
                                        fontSize: 10,
                                      ),
                                    ),
                                    initialValue: accountValue,
                                    onSaved: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        accountValue = value;
                                        print(accountValue);
                                      });
                                    },
                                  ),
                                  MultiSelectFormField(
                                    autovalidate: AutovalidateMode.disabled,
                                    chipBackGroundColor: Colors.red,
                                    chipLabelStyle:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    dialogTextStyle:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    checkBoxActiveColor: Colors.red,
                                    checkBoxCheckColor: Colors.white,
                                    dialogShapeBorder: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12.0))),
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
                                      "إختر قسم أو أكثر",
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
                                  ),
                                ],
                              )
                            : Row(),
                      ],
                    ),
                  ),
                  // SizedBox(height: 30),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(width: 3),
                      Expanded(
                        child: MaterialButton(
                          onPressed: () async {
                            var newUserAccounType = 'regular-user';
                            var name = _nameController.text;
                            var userNameText = _userNameController.text;
                            var userPasswordText = _userPasswordController.text;
                            var userMailText = _userMailController.text;
                            var userHierarchyText =
                                _userHierarchyController.text;
                            if (name.isEmpty || name.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "لا يمكن إضافة إسم المستخدم فارغ",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            } else if (userNameText.isEmpty ||
                                userNameText.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "من فضلك تأكد من إسم المستخدم",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            } else if (userPasswordText.isEmpty ||
                                userPasswordText.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "من فضلك تأكد من كلمة المرور",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            } else if (userMailText.isEmpty ||
                                userMailText.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "من فضلك تأكد من البريد الإلكتروني",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            } else if (!userMailText.contains('@')) {
                              Fluttertoast.showToast(
                                  msg: "من فضلك تأكد من صيغة البريد الإلكتروني",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            } else if (userPasswordText.isEmpty ||
                                userPasswordText.length == 0) {
                              Fluttertoast.showToast(
                                  msg: "من فضلك تأكد من صيغة البريد الإلكتروني",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            } else {
                              List<List<String>> fullHira2 = [];
                              if (userHierarchyText.length > 1) {
                                List orgLevels = userHierarchyText.split(';');
                                // print('orgLevels0: ' + orgLevels[0]);
                                // print('orgLevels1: ' + orgLevels[1]);
                                for (var i in orgLevels) {
                                  print('orgLevels[i]: ' + i);
                                  List<String> departementsLevel =
                                      i.toString().split(',');
                                  print('departementsLevel: ' +
                                      departementsLevel.toString());
                                  fullHira2.add(departementsLevel);
                                }
                              }
                              // print("fullHira: " + fullHira2.toString());
                              // if (hasCreateOrganization) {
                              //   newUserAccounType = accountValue[0].toString();
                              // }
                              if (accountValue.length > 0) {
                                newUserAccounType = accountValue[0];
                              }
                              NewUser _newUser = NewUser(
                                name,
                                newUserAccounType,
                                userNameText,
                                userMailText,
                                userPasswordText,
                                depValue,
                              );
                              if (!regularUserValue) {
                                _newUser.hierarchy = fullHira2;
                              }
                              addResponse =
                                  await _usersProvider.createNewUser(_newUser);
                              print(addResponse);
                              if (addResponse == true) {
                                clearTextController();
                                setState(() {
                                  // Navigator.pop(context);
                                  // Navigator.of(context)
                                  //     .pushReplacementNamed("/userManagement");
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/userManagement',
                                      (Route<dynamic> route) => false);
                                  print(name);
                                  print(accountValue);
                                  print(userNameText);
                                  print(userPasswordText);
                                  print(userMailText);
                                  print(depValue);
                                  print(fullHira2.toString());
                                });
                              }
                            }
                          },
                          child: Text(
                            "أرسل",
                            style: TextStyle(
                                fontFamily: 'Jazeera',
                                color: Colors.white,
                                fontSize: 12),
                          ),
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 3),
                      Expanded(
                        child: MaterialButton(
                          onPressed: () {
                            clearTextController();
                            setState(() {
                              Navigator.pop(context);
                            });
                          },
                          child: Text(
                            "إلغاء",
                            style: TextStyle(
                                fontFamily: 'Jazeera',
                                color: Colors.white,
                                fontSize: 12),
                          ),
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(width: 3),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  clearTextController() {
    _nameController.clear();
    _accountTypeController.clear();
    _userNameController.clear();
    _userPasswordController.clear();
    _userMailController.clear();
    _userDepartmentsController.clear();
    _userHierarchyController.clear();
  }
}
