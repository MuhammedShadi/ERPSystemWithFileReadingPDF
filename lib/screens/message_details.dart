import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:pdfviewer/models/message_comment_item.dart';
import 'package:pdfviewer/models/user_item.dart';
import 'package:pdfviewer/providers/messages_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/providers/users_provider.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';
import 'dart:ui' as ui;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:smart_select/smart_select.dart';

MessagesProvider _messagesProvider = new MessagesProvider();
bool themeSwitched = false;
ScrollController _scrollController = ScrollController();
String text;
String oldDeadline = '';
bool visibleCommentsValue;
List<dynamic> userDepartment = [];
List<dynamic> userAccounts = [];
dynamic themeColor() {
  if (themeSwitched) {
    return Colors.grey[850];
  } else {}
}

TextEditingController _addTextController = new TextEditingController();
bool _validate = false;
bool dialVisible = true;

class MessageDetails extends StatefulWidget {
  static const routName = '/messageItemDetails';
  final String _messageItemId;
  MessageDetails(this._messageItemId);
  @override
  _MessageDetailsState createState() => _MessageDetailsState();
}

class _MessageDetailsState extends State<MessageDetails> {
  SpeedDial buildSpeedDial() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.list_view,
      animatedIconTheme: IconThemeData(size: 22.0),
      visible: dialVisible,
      curve: Curves.slowMiddle,
      children: [
        SpeedDialChild(
          child: Icon(Icons.add_comment, color: Colors.white),
          backgroundColor: Colors.green,
          onTap: () => addMessageComment(context),
          label: ' إضافة تعليق',
          labelStyle: TextStyle(
            color: Colors.white,
            fontFamily: 'Jazeera',
            fontSize: 15,
          ),
          labelBackgroundColor: Colors.green,
        ),
      ],
    );
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'عرض الرسالة',
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
                ],
              ),
            ],
          ),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/messagesManagement', (Route<dynamic> route) => false);
              })),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: SingleChildScrollView(child: getDisc(widget._messageItemId)),
      floatingActionButton: buildSpeedDial(),
    );
  }

  Widget getDisc(String discId) {
    return Container(
      color: Colors.black12,
      child: FutureBuilder<Map>(
        future: _messagesProvider.getMessage(discId),
        builder: (BuildContext context, snapshot) {
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
                          "من فضلك إنتظر يتم التحميل ... ",
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
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                          "...من فضلك إنتظر يتم التحميل",
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
          } else if (snapshot.connectionState == ConnectionState.done) {
            text = snapshot.data['text'];
            oldDeadline = snapshot.data['created_at'];
            visibleCommentsValue = snapshot.data['visible_comments'];

            ///To_Do: Change users of snapshot after handling
            userDepartment = snapshot.data['users'];
            userAccounts = snapshot.data['users'];
            return Scrollbar(
              controller: _scrollController,
              child: Column(
                children: <Widget>[
                  Wrap(
                    direction: Axis.horizontal,
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        color: Colors.white),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Wrap(
                                          direction: Axis.horizontal,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 30, right: 15, left: 15),
                                              child: Text(
                                                snapshot.data['text'],
                                                softWrap: true,
                                                maxLines: 10,
                                                style: TextStyle(
                                                  fontFamily: 'Jazeera',
                                                  color: Colors.black,
                                                  fontSize: 24.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Directionality(
                                          textDirection: ui.TextDirection.rtl,
                                          child: Wrap(
                                            direction: Axis.horizontal,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 25,
                                                    left: 25,
                                                    bottom: 20),
                                                child: Text(
                                                  snapshot.data['author'],
                                                  softWrap: true,
                                                  style: TextStyle(
                                                    fontFamily: 'Jazeera',
                                                    color: Colors.black,
                                                    fontSize: 15.0,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 0.0,
                                    top: 0.0,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: 12.0, top: 10.0),
                                      child: Text(
                                        snapshot.data['created_at']
                                            .split('T')[0],
                                        softWrap: true,
                                        maxLines: 10,
                                        style: TextStyle(
                                          fontFamily: 'Jazeera',
                                          color: Colors.black,
                                          fontSize: 15.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0.0,
                                    top: 0.0,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        Alert(
                                          context: context,
                                          title:
                                              " هل أنت متأكد من حذف الرسالة ؟",
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
                                                  Navigator.pop(context);
                                                });
                                              },
                                              child: Text(
                                                "لا",
                                                style: TextStyle(
                                                    fontFamily: 'Jazeera',
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                              color: Colors.blueGrey,
                                            ),
                                            DialogButton(
                                              onPressed: () {
                                                setState(() {
                                                  Navigator.pop(context);
                                                  _messagesProvider
                                                      .deleteMessage(
                                                          snapshot.data['_id']);
                                                  Navigator.of(context)
                                                      .pushNamedAndRemoveUntil(
                                                          '/messagesManagement',
                                                          (Route<dynamic>
                                                                  route) =>
                                                              false);
                                                });
                                              },
                                              child: Text(
                                                "نعم",
                                                style: TextStyle(
                                                    fontFamily: 'Jazeera',
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                              color: Colors.red,
                                            ),
                                          ],
                                        ).show();
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    left: 0.0,
                                    bottom: 0.0,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (context) =>
                                                  UpdateMessage(
                                                      widget._messageItemId)),
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, left: 8, top: 8),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Text(
                          'التعليقات',
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            fontSize: 15,
                            color: themeSwitched ? Colors.white : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  getDiscussionComments(widget._messageItemId),
                ],
              ),
            );
          }
          return Row();
        },
      ),
    );
  }

  addMessageComment(context) {
    setState(() {
      _addTextController.text.isEmpty ? _validate = true : _validate = false;
    });
    Alert(
      context: context,
      title: "إضافة تعليق جديد",
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
                maxLines: 70,
                minLines: 2,
                controller: _addTextController,
                cursorColor: Theme.of(context).colorScheme.secondary,
                // initialValue: 'إترك تعليقك هنا',
                decoration: InputDecoration(
                  errorText: _validate ? 'لا يجب أن يكون فارغاً' : null,
                  labelText: 'تعليق',
                  labelStyle: TextStyle(
                    fontFamily: 'Jazeera',
                    color: Colors.red,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      buttons: [
        DialogButton(
          onPressed: () {
            setState(() {
              Navigator.pop(context);
              _addTextController.clear();
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
            var text = _addTextController.text;
            setState(() {
              if (text.isEmpty || text.length == 0) {
                Fluttertoast.showToast(
                    msg: "لا يمكن إضافة تعليق فارغ",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              } else {
                _messagesProvider.addMessageComment(
                    widget._messageItemId, text);
                Navigator.pop(context);
                _addTextController.clear();
                // print(name);
              }
            });
          },
          child: Text(
            "إضافة",
            style: TextStyle(
                fontFamily: 'Jazeera', color: Colors.white, fontSize: 12),
          ),
          color: Colors.green,
        ),
      ],
    ).show();
  }

  Widget getDiscussionComments(String id) {
    return Container(
      child: FutureBuilder(
        future: _messagesProvider.getAllMessageComment(id),
        builder: (BuildContext context,
            AsyncSnapshot<List<MessageCommentItem>> snapshot) {
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
          } else if (snapshot.connectionState == ConnectionState.waiting) {
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
          } else {
            return Scrollbar(
              controller: _scrollController,
              child: Column(
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: snapshot.data.length,
                      scrollDirection: Axis.vertical,
                      //reverse: true,
                      shrinkWrap: true,
                      addAutomaticKeepAlives: false,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
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
                                              children: <Widget>[
                                                Expanded(
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 300,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                          top: 20,
                                                        ),
                                                        child: Text(
                                                          snapshot
                                                              .data[index].text,
                                                          softWrap: true,
                                                          style: new TextStyle(
                                                            color: Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
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
                              Positioned(
                                top: 0.0,
                                right: 0.0,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 18.0, top: 5),
                                  child: Row(
                                    children: [
                                      Container(
                                        child: Text(
                                          snapshot.data[index].createdAt
                                              .split('T')[0],
                                          style: new TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'Jazeera',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 4.0, left: 8),
                                        child: Container(
                                          child: Text(
                                            snapshot.data[index].author
                                                .toString(),
                                            style: new TextStyle(
                                              color: Colors.black,
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
                                ),
                              ),
                              Positioned(
                                top: 0.0,
                                left: 0.0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Alert(
                                      context: context,
                                      title: " هل أنت متأكد من حذف التعليق ؟",
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
                                              Navigator.pop(context);
                                            });
                                          },
                                          child: Text(
                                            "لا",
                                            style: TextStyle(
                                                fontFamily: 'Jazeera',
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                          color: Colors.blueGrey,
                                        ),
                                        DialogButton(
                                          onPressed: () {
                                            _messagesProvider
                                                .deleteMessageComment(
                                                    widget._messageItemId,
                                                    snapshot
                                                        .data[index].commentId);
                                            setState(() {
                                              Navigator.of(context)
                                                  .pushNamedAndRemoveUntil(
                                                      '/messagesManagement',
                                                      (Route<dynamic> route) =>
                                                          false);
                                            });
                                          },
                                          child: Text(
                                            "نعم",
                                            style: TextStyle(
                                                fontFamily: 'Jazeera',
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                          color: Colors.red,
                                        ),
                                      ],
                                    ).show();
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class UpdateMessage extends StatefulWidget {
  final String _messageItemId;
  UpdateMessage(this._messageItemId);
  @override
  _UpdateMessageState createState() => _UpdateMessageState();
}

String organizationName;
List<String> departmentsValues = [];
List<UserItem> accountsValues = [];
UsersProvider _usersProvider = new UsersProvider();
Future<bool> buildDepartment() async {
  organizationName = await ShPrefs.instance.getStringValue("organization");
  departmentsValues =
      await _usersProvider.getOrganizationDepartments(organizationName);
  accountsValues = await _usersProvider.getOwnActiveOrganizationUsers();

  return true;
}

class _UpdateMessageState extends State<UpdateMessage> {
  TextEditingController _textController = new TextEditingController(text: text);
  bool visibleComments = visibleCommentsValue;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  var isDisable = false;
  bool isAdded = false;
  Color colorAddNewDisc = Colors.orange;
  List<dynamic> depValue = [];
  List<dynamic> accValue = [];
  String deadLine = '';
  bool _validate = false;
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
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'تعديل الرسالة',
                style: TextStyle(
                  fontFamily: 'Lalezar',
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) =>
                        MessageDetails(widget._messageItemId)),
              );
            }),
      ),
      endDrawer: AppDrawer(),
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
                                                  .updateMessage(
                                                      widget._messageItemId,
                                                      _textController.text,
                                                      accValue,
                                                      depValue,
                                                      deadLine,
                                                      visibleComments)) {
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
                                    " تعديل الرسالة ",
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
