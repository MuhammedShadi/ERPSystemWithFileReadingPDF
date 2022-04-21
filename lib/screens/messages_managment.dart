import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:pagination_view/pagination_view.dart';
import 'package:pdfviewer/models/message_item.dart';
import 'package:pdfviewer/models/new_message.dart';
import 'package:pdfviewer/models/user_item.dart';
import 'package:pdfviewer/providers/log_provider.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/messages_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/providers/users_provider.dart';
import 'package:pdfviewer/screens/message_details.dart';
import 'package:pdfviewer/screens/search_screen.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';
import 'package:smart_select/smart_select.dart';

Timer timer;
bool themeSwitched = false;
dynamic themeColor() {
  if (themeSwitched) {
    return Colors.grey[850];
  } else {}
}

LogProvider _logProvider = new LogProvider();
bool hasCreateMessagePermission;
bool hasManageMessagePermissions = false;
bool permissionsHasBeenSet = false;
bool _validate = false;
UsersProvider _usersProvider = new UsersProvider();
LoginProvider _loginProvider = new LoginProvider();
MessagesProvider _messagesProvider = new MessagesProvider();
String deadLine = '';

class MessagesManagment extends StatefulWidget {
  static const routName = '/messagesManagement';
  @override
  _MessagesManagmentState createState() => _MessagesManagmentState();
}

class _MessagesManagmentState extends State<MessagesManagment> {
  int page;
  PaginationViewType paginationViewType;
  GlobalKey<PaginationViewState> key;

  @override
  void initState() {
    page = 0;
    paginationViewType = PaginationViewType.listView;
    key = GlobalKey<PaginationViewState>();
    disableSecureScreen();
    super.initState();
    timer = Timer.periodic(Duration(minutes: 5), (Timer t) {
      _loginProvider.deleteCacheAndAppDir();
    });
  }

  Future<void> disableSecureScreen() async {
    // print('secureScreen');
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }

  Future<Null> checkMessagePermissions() async {
    hasCreateMessagePermission = false;
    if (await ShPrefs.instance.containsKey('permissions')) {
      String permissionsFromShPre =
          await ShPrefs.instance.getStringValue('permissions');
      //print(permissionsFromShPre);
      permissionsHasBeenSet = true;
      hasCreateMessagePermission =
          permissionsFromShPre.contains("create-discussion");
      hasManageMessagePermissions =
          permissionsFromShPre.contains('view::acked|dead|deleted::discussion');
      setState(() {});
    }
  }

  Future<bool> buildDepartment() async {
    organizationName = await ShPrefs.instance.getStringValue("organization");
    departmentsValues =
        await _usersProvider.getOrganizationDepartments(organizationName);
    accountsValues = await _usersProvider.getOwnActiveOrganizationUsers();

    return true;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  "إدارة الرسائل",
                  style: TextStyle(
                    fontFamily: 'Jazeera',
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
                      onPressed: () => setState(() =>
                          paginationViewType = PaginationViewType.gridView),
                    )
                  : IconButton(
                      icon: Icon(Icons.list),
                      onPressed: () => setState(() =>
                          paginationViewType = PaginationViewType.listView),
                    ),
              // IconButton(
              //   icon: Icon(Icons.refresh),
              //   onPressed: () => key.currentState.refresh(),
              // ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                      builder: (context) => SearchScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(
              Icons.add_box,
              color: Colors.white,
            ),
            onPressed: () async {
              await buildDepartment();
              Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (context) => AddNewMessages(),
                ),
              );
            },
          )),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: getMessagesData(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 300.0),
        child: FloatingActionButton(
          onPressed: () {
            _logProvider.viewLog();
          },
          tooltip: 'Search',
          child: Icon(Icons.filter_list),
        ),
      ),
    );
  }

  Widget getMessagesData() {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        color: Colors.black12,
        child: PaginationView<MessageItem>(
          key: key,
          paginationViewType: paginationViewType,
          itemBuilder: (BuildContext context, MessageItem message, int index) =>
              (paginationViewType == PaginationViewType.listView)
                  ? InkWell(
                      onTap: () async {
                        Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) => MessageDetails(message.id)),
                        );
                      },
                      child: Stack(children: [
                        Card(
                          color: themeColor(),
                          margin: const EdgeInsets.only(
                              left: 5.0, right: 5.0, bottom: 10.0, top: 3.0),
                          elevation: 4.0,
                          child: Column(
                            children: [
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.messenger_outline,
                                    size: 35,
                                    color: themeSwitched
                                        ? Colors.white
                                        : Colors.redAccent,
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Row(
                                          // mainAxisAlignment:
                                          //     MainAxisAlignment.start,
                                          children: <Widget>[
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Container(
                                                  child: Text(
                                                    message.text,
                                                    style: new TextStyle(
                                                      color: themeSwitched
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Container(
                                                  child: Text(
                                                    message.author,
                                                    style: new TextStyle(
                                                      color: themeSwitched
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Container(
                                                  child: Text(
                                                    message.createdAt
                                                            .split("T")[0] +
                                                        '  ' +
                                                        message.createdAt
                                                            .split("T")[1]
                                                            .split('.')[0],
                                                    style: new TextStyle(
                                                      color: themeSwitched
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.end,
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
                            ],
                          ),
                        ),
                      ]),
                    )
                  : Stack(children: [
                      Card(
                        color: themeColor(),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) =>
                                      MessageDetails(message.id)),
                            );
                          },
                          child: GridTile(
                            child: Container(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.messenger_outline,
                                              size: 40,
                                              color: themeSwitched
                                                  ? Colors.white
                                                  : Colors.redAccent,
                                            ),
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
                                                    message.text,
                                                    style: new TextStyle(
                                                      color: themeSwitched
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                    message.author,
                                                    style: new TextStyle(
                                                      color: themeSwitched
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                    message.createdAt
                                                            .split("T")[0] +
                                                        '  ' +
                                                        message.createdAt
                                                            .split("T")[1]
                                                            .split('.')[0],
                                                    style: new TextStyle(
                                                      color: themeSwitched
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: 'Jazeera',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
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
                    ]),
          pageFetch: pageFetch,
          //pageRefresh: pageRefresh,
          pullToRefresh: true,
          onError: (dynamic error) => Center(
            child: Text('Some error occured' + error.toString()),
          ),
          onEmpty: Center(
            child: Text(
              'لا توجد رسائل ',
              style: TextStyle(
                  fontSize: 15, fontFamily: 'Jazeera', color: Colors.red),
            ),
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

  Future<List<MessageItem>> pageFetch(int offset) async {
    page++;
    // print('test here!');
    final List<MessageItem> nextMessageList =
        await _messagesProvider.getAllMessagesP(pageNum: page);
    await Future<List<MessageItem>>.delayed(Duration(milliseconds: 30));
    var maxPage = 0;
    String maxPageS = await ShPrefs.instance.getStringValue('messagesPages');

    if (maxPageS != "") {
      maxPage = int.parse(maxPageS);
    }
    return page == maxPage + 1 ? [] : nextMessageList;
  }

  Future<List<MessageItem>> pageRefresh(int offset) async {
    page = 0;
    return pageFetch(offset);
  }
}

String organizationName;
List<String> departmentsValues = [];
List<UserItem> accountsValues = [];
Future<bool> buildDepartment() async {
  organizationName = await ShPrefs.instance.getStringValue("organization");
  departmentsValues =
      await _usersProvider.getOrganizationDepartments(organizationName);
  accountsValues = await _usersProvider.getOwnActiveOrganizationUsers();

  return true;
}

class AddNewMessages extends StatefulWidget {
  @override
  _AddNewMessagesState createState() => _AddNewMessagesState();
}

class _AddNewMessagesState extends State<AddNewMessages> {
  TextEditingController _textController = new TextEditingController();
  bool visibleComments = true;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  var isDisable = false;
  bool isAdded = false;
  Color colorAddNewDisc = Colors.green;
  List<dynamic> depValue = [];
  List<dynamic> accValue = [];
  List<dynamic> userDepartment = [];
  List<dynamic> userAccounts = [];
  List departmentsOptions = List.generate(
      departmentsValues.length,
      (index) => {
            "display": departmentsValues[index],
            "value": departmentsValues[index]
          });
  List accountsOptions = List.generate(
      accountsValues.length,
      (index) => {
            "display": accountsValues[index].username,
            "value": accountsValues[index].username
          });
  _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // Refer step 1
      firstDate: DateTime(2021),
      lastDate: DateTime(2035),
    );
    compileDateTime();
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    //'%Y-%m-%dT%H:%M:%S.%f%z'
    compileDateTime();
    if (picked != null && picked != selectedTime)
      setState(() {
        setState(() {
          selectedTime = picked;
        });
      });
  }

  compileDateTime() {
    deadLine = selectedDate.year.toString() +
        '-' +
        selectedDate.month.toString().padLeft(2, '0') +
        '-' +
        selectedDate.day.toString().padLeft(2, '0') +
        'T' +
        selectedTime.hour.toString() +
        ':' +
        selectedTime.minute.toString() +
        ':' +
        '00.000Z';
    // print(deadLine);
  }

  List<S2Choice<bool>> visibleCommentsOptions = [
    S2Choice<bool>(value: false, title: 'لا أُريد'),
    S2Choice<bool>(value: true, title: 'نعم أُريد'),
  ];

  clearTextController() {
    setState(() {
      _textController.clear();
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    compileDateTime();
    setState(() {
      _textController.text.isEmpty ? _validate = true : _validate = false;
    });
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
                "إرسال رسالة جديدة",
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
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed("/messagesManagement");
          },
        ),
      ),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: themeColor(),
          child: Stack(
            children: [
              Opacity(
                opacity: 1,
                child: AbsorbPointer(
                  absorbing: isAdded,
                  child: SingleChildScrollView(
                    child: Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: Column(
                        children: [
                          TextFormField(
                            maxLines: 2,
                            minLines: 1,
                            controller: _textController,
                            cursorColor:
                                Theme.of(context).colorScheme.secondary,
                            // initialValue: 'إترك تعليقك هنا',
                            decoration: InputDecoration(
                              errorText:
                                  _validate ? 'النص لا يكون فارغاً' : null,
                              labelText: 'نص الرسالة:',
                              errorStyle: TextStyle(
                                  color: Colors.red,
                                  fontFamily: 'Jazeera',
                                  fontSize: 10),
                              labelStyle: TextStyle(
                                  color: Colors.red,
                                  fontFamily: 'Jazeera',
                                  fontSize: 15),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                            onChanged: (text) {
                              text = _textController.text;
                            },
                          ),
                          Directionality(
                              textDirection: ui.TextDirection.rtl,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'تاريخ الإرسال:',
                                  labelStyle: TextStyle(
                                      fontFamily: 'Jazeera',
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                                enabled: false,
                              )),
                          Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      child: IconButton(
                                          icon: Icon(
                                            Icons.timer_sharp,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _selectTime(context)),
                                    ),
                                    InkWell(
                                      child: Text(
                                        "${selectedTime.format(context)}"
                                            .split(' ')[0],
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                        textAlign: TextAlign.start,
                                      ),
                                      onTap: () {
                                        _selectTime(context);
                                      },
                                    ),
                                    SizedBox(width: 20),
                                    InkWell(
                                      onTap: () {
                                        _selectDate(context);
                                      },
                                      child: Text(
                                        "${selectedDate.toLocal()}"
                                            .split(' ')[0],
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: IconButton(
                                          icon: Icon(
                                            Icons.date_range_outlined,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _selectDate(context)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // ignore: deprecated_member_use
                                    RaisedButton(
                                      onPressed: () {
                                        compileDateTime();
                                        setState(() {
                                          selectedTime = TimeOfDay.fromDateTime(
                                              DateTime.now()
                                                  .add(Duration(hours: 6)));
                                        });
                                      }, //er step 3
                                      child: Text(
                                        'بعد 6 ساعات',
                                        style: TextStyle(
                                            fontFamily: 'Jazeera',
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 3),
                                    // ignore: deprecated_member_use
                                    RaisedButton(
                                      onPressed: () {
                                        compileDateTime();
                                        setState(() {
                                          selectedDate = DateTime.now()
                                              .add(Duration(days: 1));
                                        });
                                      }, //
                                      child: Text(
                                        'بعد يوم',
                                        style: TextStyle(
                                            fontFamily: 'Jazeera',
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 3),
                                    // ignore: deprecated_member_use
                                    RaisedButton(
                                      onPressed: () {
                                        compileDateTime();
                                        setState(() {
                                          selectedDate = DateTime.now()
                                              .add(Duration(days: 3));
                                        });
                                      }, //er step 3
                                      child: Text(
                                        'بعد 3 أيام',
                                        style: TextStyle(
                                            fontFamily: 'Jazeera',
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 3),
                                    // ignore: deprecated_member_use
                                    RaisedButton(
                                      onPressed: () {
                                        compileDateTime();
                                        setState(() {
                                          selectedDate = DateTime.now()
                                              .add(Duration(days: 7));
                                        });
                                      }, // Refer step 3
                                      child: Text(
                                        'بعد أسبوع',
                                        style: TextStyle(
                                            fontFamily: 'Jazeera',
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: (MediaQuery.of(context).size.width /
                                            2) -
                                        10,
                                    child: MultiSelectFormField(
                                      autovalidate: AutovalidateMode.disabled,
                                      chipBackGroundColor: Colors.red,
                                      chipLabelStyle: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      dialogTextStyle: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      checkBoxActiveColor: Colors.red,
                                      checkBoxCheckColor: Colors.white,
                                      dialogShapeBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12.0))),
                                      title: Text(
                                        "الأقسام المُرسل إليهم:",
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
                                          // print(depValue);
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    width: (MediaQuery.of(context).size.width /
                                            2) -
                                        23,
                                    child: MultiSelectFormField(
                                      trailing: Icon(Icons.add_box),
                                      autovalidate: AutovalidateMode.disabled,
                                      chipBackGroundColor: Colors.red,
                                      chipLabelStyle: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      dialogTextStyle: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      checkBoxActiveColor: Colors.red,
                                      checkBoxCheckColor: Colors.white,
                                      dialogShapeBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12.0))),
                                      title: Text(
                                        "المُستخدمين المُرسل إليهم:",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontFamily: 'Jazeera',
                                          fontSize: 14,
                                        ),
                                      ),
                                      dataSource: accountsOptions,
                                      textField: 'display',
                                      valueField: 'value',
                                      okButtonLabel: 'تم',
                                      cancelButtonLabel: 'إلغاء',
                                      hintWidget: Text(
                                        userAccounts
                                                    .toString()
                                                    .replaceAll('[', '')
                                                    .replaceAll(']', '') ==
                                                ''
                                            ? 'لا يوجد مستخدمين'
                                            : userAccounts
                                                .toString()
                                                .replaceAll('[', '')
                                                .replaceAll(']', ''),
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontFamily: 'Jazeera',
                                          fontSize: 10,
                                        ),
                                      ),
                                      initialValue: accValue,
                                      onSaved: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          accValue = value;
                                          // print(accValue);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SmartSelect<bool>.single(
                            title: 'هل تُريد إظهار التعليقات مُفعل أم لا ؟',
                            value: visibleComments,
                            choiceItems: visibleCommentsOptions,
                            onChange: (state) => setState(() {
                              visibleComments = state.value;
                              print(visibleComments);
                            }),
                            placeholder:
                                'هل تُريد إظهار التعليقات مُفعل أم لا ؟',
                            choiceStyle: S2ChoiceStyle(
                              color: Colors.blue,
                              titleStyle: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Jazeera',
                                fontSize: 15,
                              ),
                              accentColor: Colors.green,
                              activeAccentColor: Colors.orange,
                              activeColor: Colors.purpleAccent,
                              activeBrightness: Brightness.dark,
                              activeBorderOpacity: 10,
                              borderOpacity: 10,
                              brightness: Brightness.light,
                              highlightColor: Colors.cyanAccent,
                              subtitleStyle: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Jazeera',
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Divider(),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: MaterialButton(
                                  onPressed: isDisable
                                      ? () => () {}
                                      : () async {
                                          CreateMessageItem _newMessageItem =
                                              CreateMessageItem(
                                            _textController.text,
                                            accValue,
                                            deadLine,
                                            depValue,
                                            visibleComments,
                                          );

                                          if (_textController.text.isEmpty) {
                                            Fluttertoast.showToast(
                                                msg:
                                                    "لا يمكن إضافة بإسم نقاش فارغ",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                timeInSecForIosWeb: 1,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                                fontSize: 16.0);
                                          } else {
                                            setState(() {
                                              isDisable = true;
                                              colorAddNewDisc = Colors.black12;
                                              isAdded = true;
                                            });
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 1000),
                                                () async {
                                              if (await _messagesProvider
                                                  .addNewMessage(
                                                      _newMessageItem)) {
                                                clearTextController();
                                                await Navigator.of(context)
                                                    .pushReplacementNamed(
                                                        "/messagesManagement");
                                              }
                                              setState(() {});
                                            });

                                            // if () {
                                            // }
                                          }
                                        },
                                  child: Text(
                                    " إرسال الرسالة ",
                                    style: TextStyle(
                                      fontFamily: 'Jazeera',
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  color: colorAddNewDisc,
                                ),
                              ),
                              SizedBox(width: 3),
                              Expanded(
                                child: MaterialButton(
                                  onPressed: () {
                                    clearTextController();
                                  },
                                  child: Text(
                                    "مسح البيانات",
                                    style: TextStyle(
                                      fontFamily: 'Jazeera',
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  color: themeSwitched
                                      ? Colors.white10
                                      : Colors.blueAccent,
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
              Opacity(
                opacity: isAdded ? 1.0 : 0,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
