import 'dart:io';
import 'dart:ui' as ui;
import 'package:clipboard/clipboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfviewer/models/discussion_comment_item.dart';
import 'package:pdfviewer/models/user_item.dart';
import 'package:pdfviewer/providers/discussions_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/providers/users_provider.dart';
import 'package:pdfviewer/screens/pdf_viewer_screen.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

UsersProvider _usersProvider = new UsersProvider();
DiscussionsProvider _discussionsProvider = new DiscussionsProvider();
ScrollController _scrollController = ScrollController();
TextEditingController _addTextController = new TextEditingController();
bool _validate = false;
ScrollController scrollController;
bool dialVisible = true;

List<dynamic> depValue = [];
List<dynamic> accValue = [];
List<dynamic> tagsValue = [];
List<dynamic> userDepartment = [];
List<dynamic> userAccounts = [];
List<dynamic> userFiles = [];
List<dynamic> userTags = [];
List<dynamic> discussionFiles = [];
String oldDeadline = '';
String deadLine = '';
bool themeSwitched = false;
bool isInit = true;
bool arrowBool = false;
List<File> savedFiles;
File singleFile;
String userName;
String userId;
String userDiscription;
bool deleted;
String discriptionTitle;
String discriptionComments;

class DiscussionsDetails extends StatefulWidget {
  static const routName = '/discussionsItemDetails';
  final String _discussionItem;

  DiscussionsDetails(this._discussionItem);

  @override
  _DiscussionsDetailsState createState() => _DiscussionsDetailsState();
}

class _DiscussionsDetailsState extends State<DiscussionsDetails> {
  bool hasDeleteDiscussionsPermission = true;
  bool hasUpdateDiscussionsPermission = true;
  bool hasDeleteCommentPermission = true;
  bool hasViewCommentPermission = true;
  bool hasDeleteDiscussionsValue = true;
  bool accountTypeValue = false;
  String deletedValuePermission = '';

  Future<void> secureScreen() async {
    //print('secureScreen');
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void checkAccountTypeValue() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("accountType");
    if (userPermission == "organization") {
      accountTypeValue = true;
    } else {
      accountTypeValue = false;
    }
  }

  void checkDeleteDiscussionsPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    if (userPermission.contains("delete-discussion")) {
      hasDeleteDiscussionsPermission = true;
    } else {
      hasDeleteDiscussionsPermission = false;
    }
  }

  void checkUpdateDiscussionsPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    //print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermission.contains("update-discussion")) {
      hasUpdateDiscussionsPermission = true;
    } else {
      hasUpdateDiscussionsPermission = false;
    }
  }

  void checkDeleteCommentPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    //print(await ShPrefs.instance.getStringValue("permissions"));
    if (userPermission.contains("delete-comment")) {
      hasDeleteCommentPermission = true;
    } else {
      hasDeleteCommentPermission = false;
    }
  }

  void checkViewCommentPermissions() async {
    String userPermission =
        await ShPrefs.instance.getStringValue("permissions");
    if (userPermission.contains("view::acked|dead|deleted::comment")) {
      // print(userPermission.contains("view-comment"));
      hasViewCommentPermission = true;
    } else {
      hasViewCommentPermission = false;
    }
  }

  void checkDeleteDiscussionsValue() async {
    deletedValuePermission =
        await ShPrefs.instance.getStringValue("deletedValue");
    //print(deletedValuePermission);
    // print('ss');
    if (deletedValuePermission == 'true') {
      setState(() {
        hasDeleteDiscussionsValue = false;
      });
    } else {
      setState(() {
        hasDeleteDiscussionsValue = true;
      });
    }
  }

  @override
  void initState() {
    secureScreen();
    checkDeleteDiscussionsValue();
    checkDeleteDiscussionsPermissions();
    checkUpdateDiscussionsPermissions();
    checkDeleteCommentPermissions();
    checkViewCommentPermissions();
    checkDeleteDiscussionsValue();
    checkAccountTypeValue();
    super.initState();

    scrollController = ScrollController()
      ..addListener(() {
        setDialVisible(scrollController.position.userScrollDirection ==
            ScrollDirection.forward);
      });
  }

  void setDialVisible(bool value) {
    setState(() {
      dialVisible = value;
    });
  }

  void checkCopiedValues() async {
    if (userDiscription.isNotEmpty) {
      await FlutterClipboard.copy(userDiscription);
    }
    if (discriptionTitle.isNotEmpty) {
      await FlutterClipboard.copy(discriptionTitle);
    }
  }

  SpeedDial buildSpeedDial() {
    return accountTypeValue == false
        ? SpeedDial(
            animatedIcon: AnimatedIcons.list_view,
            animatedIconTheme: IconThemeData(size: 22.0),
            visible: dialVisible,
            curve: Curves.bounceIn,
            children: [
              SpeedDialChild(
                child: Icon(Icons.add_comment, color: Colors.white),
                backgroundColor: Colors.deepOrange,
                onTap: () => addDiscussionComment(context),
                label: ' إضافة تعليق مع تم الإطلاع',
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Jazeera',
                  fontSize: 15,
                ),
                labelBackgroundColor: Colors.deepOrangeAccent,
              ),
              SpeedDialChild(
                child: Icon(Icons.check_circle, color: Colors.white),
                backgroundColor: Colors.green,
                onTap: () => addDiscussionAckn(context),
                label: 'تم الإطلاع',
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Jazeera',
                  fontSize: 15,
                ),
                labelBackgroundColor: Colors.green,
              ),
            ],
          )
        : SpeedDial(
            animatedIcon: AnimatedIcons.list_view,
            animatedIconTheme: IconThemeData(size: 22.0),
            visible: dialVisible,
            curve: Curves.bounceIn,
            children: [
              SpeedDialChild(
                child: Icon(Icons.add_comment, color: Colors.white),
                backgroundColor: Colors.deepOrange,
                onTap: () => addDiscussionComment(context),
                label: ' إضافة تعليق مع تم الإطلاع',
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Jazeera',
                  fontSize: 15,
                ),
                labelBackgroundColor: Colors.deepOrangeAccent,
              ),
              SpeedDialChild(
                child: Icon(Icons.copy, color: Colors.white),
                backgroundColor: Colors.indigo,
                onTap: () async {
                  print(userDiscription);
                  print(discriptionTitle);
                  checkCopiedValues();
                  Fluttertoast.showToast(
                    msg: "تم نسخ المحتوى بنجاح ",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                },
                label: 'نسخ المحتوى',
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Jazeera',
                  fontSize: 15,
                ),
                labelBackgroundColor: Colors.indigo,
              ),
              SpeedDialChild(
                child: Icon(Icons.check_circle, color: Colors.white),
                backgroundColor: Colors.green,
                onTap: () => addDiscussionAckn(context),
                label: 'تم الإطلاع',
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

  bool themeSwitched = false;

  dynamic themeColor() {
    if (themeSwitched) {
      return Colors.grey[850];
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    if (deletedValuePermission == '') {
      checkDeleteDiscussionsValue();
      checkDeleteDiscussionsPermissions();
      checkUpdateDiscussionsPermissions();
      checkDeleteCommentPermissions();
      checkViewCommentPermissions();
      checkDeleteDiscussionsValue();
      checkAccountTypeValue();
    }
    // buildDepartment();

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
                  'عرض المناقشة',
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/discussionsManagement', (Route<dynamic> route) => false);
              })),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: WillPopScope(
        onWillPop: () async {
          return Navigator.canPop(context);
        },
        child: SingleChildScrollView(
            child: Column(
          children: [
            getDisc(widget._discussionItem),
            SizedBox(
              width: 10,
            ),
          ],
        )),
      ),
      resizeToAvoidBottomInset: true,
      floatingActionButton:
          hasDeleteDiscussionsValue == true ? buildSpeedDial() : Row(),
    );
  }

  Widget getDisc(String discId) {
    return Container(
      color: Colors.black12,
      child: FutureBuilder<Map>(
        future: _discussionsProvider.getDiscussion(discId),
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
          print(snapshot.connectionState);
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
            Future<File> getSingleFilePath(Map<String, dynamic> file) async {
              // print('getFilePath');
              File savedFiles = await _discussionsProvider.getSingleAttachments(
                  snapshot.data['_id'], file);
              // print(savedFiles);
              return savedFiles;
            }

            List numberOfSelectedFiles = [];
            userName = snapshot.data['name'];
            userId = snapshot.data['_id'];
            userDiscription = snapshot.data['description'];
            numberOfSelectedFiles.add(snapshot.data['files']);
            userDepartment = snapshot.data['departments'];
            userAccounts = snapshot.data['users'];
            userFiles = snapshot.data['files'];
            discussionFiles = snapshot.data['files'];
            userTags = snapshot.data['tags'];
            oldDeadline = snapshot.data['deadline'];
            deleted = snapshot.data["deleted"];
            discriptionTitle = snapshot.data["name"];
            print('tags' + snapshot.data['tags'].toString());
            print(snapshot.data);
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
                                                snapshot.data['name'],
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
                                                  snapshot.data['description'],
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
                                  hasUpdateDiscussionsPermission &&
                                          snapshot.data["deleted"] == false
                                      ? Positioned(
                                          left: 0.0,
                                          top: 0.0,
                                          child:
                                              hasDeleteDiscussionsPermission &&
                                                      snapshot.data[
                                                              "deleted"] ==
                                                          false
                                                  ? IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        Alert(
                                                          context: context,
                                                          title:
                                                              " هل أنت متأكد من حذف النقاش ؟",
                                                          style: AlertStyle(
                                                            titleStyle:
                                                                TextStyle(
                                                              color:
                                                                  Colors.indigo,
                                                              fontFamily:
                                                                  'Jazeera',
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
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12),
                                                              ),
                                                              color: Colors
                                                                  .blueGrey,
                                                            ),
                                                            DialogButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  Navigator.pop(
                                                                      context);
                                                                  _discussionsProvider
                                                                      .deleteDiscussion(
                                                                          snapshot
                                                                              .data['_id']);
                                                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                                                      '/discussionsManagement',
                                                                      (Route<dynamic>
                                                                              route) =>
                                                                          false);
                                                                });
                                                              },
                                                              child: Text(
                                                                "نعم",
                                                                style: TextStyle(
                                                                    fontFamily:
                                                                        'Jazeera',
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12),
                                                              ),
                                                              color: Colors.red,
                                                            ),
                                                          ],
                                                        ).show();
                                                      },
                                                    )
                                                  : Row(),
                                        )
                                      : Positioned(
                                          left: 0.0,
                                          top: 0.0,
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
                                                        UpdateDisc()),
                                              );
                                            },
                                          ),
                                        ),
                                  hasUpdateDiscussionsPermission &&
                                          snapshot.data["deleted"] == false
                                      ? Positioned(
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
                                                        UpdateDisc()),
                                              );
                                            },
                                          ),
                                        )
                                      : Positioned(
                                          left: 15.0,
                                          bottom: 5.0,
                                          child: Icon(
                                            Icons.flag,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  snapshot.data['tags']
                              .toString()
                              .replaceAll('[', '')
                              .replaceAll(']', '')
                              .isEmpty ||
                          snapshot.data['tags']
                                  .toString()
                                  .replaceAll('[', '')
                                  .replaceAll(']', '') ==
                              null ||
                          snapshot.data['tags'] == []
                      ? Row()
                      : Padding(
                          padding: const EdgeInsets.only(
                              left: 8.0, right: 8.0, bottom: 4),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white54,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: Text(
                                'العلامات',
                                style: TextStyle(
                                  fontFamily: 'Jazeera',
                                  fontSize: 15,
                                  color:
                                      themeSwitched ? Colors.white : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                  snapshot.data['tags']
                              .toString()
                              .replaceAll('[', '')
                              .replaceAll(']', '')
                              .isEmpty ||
                          snapshot.data['tags']
                                  .toString()
                                  .replaceAll('[', '')
                                  .replaceAll(']', '') ==
                              null ||
                          snapshot.data['tags'] == []
                      ? Row()
                      : Wrap(
                          direction: Axis.horizontal,
                          children: [
                            Container(
                              child: Column(
                                children: [
                                  Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        left: 8,
                                        top: 4,
                                      ),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            color: Colors.white),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8),
                                                  child: Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8),
                                                        child: Text(
                                                          snapshot.data['tags']
                                                              .toString()
                                                              .replaceAll(
                                                                  '[', '')
                                                              .replaceAll(
                                                                  ']', ''),
                                                          softWrap: true,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 15.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 8.0, right: 8.0, top: 8),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Text(
                          'المرفقات',
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            fontSize: 15,
                            color: themeSwitched ? Colors.white : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    direction: Axis.horizontal,
                    children: [
                      Container(
                        child: Column(
                          children: [
                            for (var i in snapshot.data['files'])
                              InkWell(
                                onTap: () async {
                                  singleFile = await getSingleFilePath(i);

                                  ShPrefs.instance.setStringValue(
                                      'filetoviewpath', singleFile.path);
                                  // print('Clicked');
                                  // loadFile(loadFileValue[0]);

                                  // loadFile(singleFile);
                                  Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => PdfViewerScreen(
                                            widget._discussionItem)),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      // height: 100,
                                      child: ListView.builder(
                                        physics: ScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: numberOfSelectedFiles.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10))),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                                left: 8,
                                                top: 4,
                                              ),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                    color: Colors.white),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  right: 8),
                                                          child: Row(
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 8),
                                                                child: Wrap(
                                                                  children: [
                                                                    Container(
                                                                      width:
                                                                          300,
                                                                      child:
                                                                          Text(
                                                                        i["name"],
                                                                        softWrap:
                                                                            true,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontFamily:
                                                                              'Jazeera',
                                                                          fontSize:
                                                                              12.0,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.right,
                                                                        overflow:
                                                                            TextOverflow.visible,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 8),
                                                                child:
                                                                    Container(
                                                                  child: Icon(
                                                                    Icons
                                                                        .attach_file,
                                                                    color: Colors
                                                                        .red,
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
                          ':مَن أتمَّ الإطلاع  ',
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            fontSize: 15,
                            color: themeSwitched ? Colors.white : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  getDiscussionAckUsers(userId),
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
                  getDiscussionComments(widget._discussionItem),
                ],
              ),
            );
          }
          return Row();
        },
      ),
    );
  }

  Widget getDiscussionComments(String id) {
    return Container(
      child: FutureBuilder(
        future: _discussionsProvider.getAllDiscussionComment(id),
        builder: (BuildContext context,
            AsyncSnapshot<List<DiscussionCommentItem>> snapshot) {
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
                          child: snapshot.data[index].deleted == false
                              ? Stack(
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
                                                                    .data[index]
                                                                    .text,
                                                                softWrap: true,
                                                                style:
                                                                    new TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontFamily:
                                                                      'Jazeera',
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
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
                                    snapshot.data[index].deleted == false
                                        ? Positioned(
                                            top: 0.0,
                                            left: 0.0,
                                            child: hasDeleteCommentPermission &&
                                                    hasDeleteDiscussionsValue
                                                ? IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      Alert(
                                                        context: context,
                                                        title:
                                                            " هل أنت متأكد من حذف التعليق ؟",
                                                        style: AlertStyle(
                                                          titleStyle: TextStyle(
                                                            color:
                                                                Colors.indigo,
                                                            fontFamily:
                                                                'Jazeera',
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
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12),
                                                            ),
                                                            color:
                                                                Colors.blueGrey,
                                                          ),
                                                          DialogButton(
                                                            onPressed: () {
                                                              _discussionsProvider
                                                                  .deleteDiscussionComment(
                                                                      widget
                                                                          ._discussionItem,
                                                                      snapshot
                                                                          .data[
                                                                              index]
                                                                          .commentId);
                                                              setState(() {
                                                                Navigator.of(
                                                                        context)
                                                                    .pushNamedAndRemoveUntil(
                                                                        '/discussionsManagement',
                                                                        (Route<dynamic>
                                                                                route) =>
                                                                            false);
                                                              });
                                                            },
                                                            child: Text(
                                                              "نعم",
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Jazeera',
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12),
                                                            ),
                                                            color: Colors.red,
                                                          ),
                                                        ],
                                                      ).show();
                                                    },
                                                  )
                                                : Row(),
                                          )
                                        : Positioned(
                                            bottom: 5.0,
                                            left: 10.0,
                                            child: Icon(
                                              Icons.flag,
                                              color: Colors.red,
                                              size: 20,
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
                                  ],
                                )
                              : Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, right: 8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.red.shade50,
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
                                                            child: Text(
                                                              snapshot
                                                                  .data[index]
                                                                  .text,
                                                              maxLines: 10,
                                                              softWrap: true,
                                                              style:
                                                                  new TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontFamily:
                                                                    'Jazeera',
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                  Wrap(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      right:
                                                                          8.0,
                                                                      bottom:
                                                                          4),
                                                              child: Container(
                                                                child: Text(
                                                                  snapshot
                                                                      .data[
                                                                          index]
                                                                      .author
                                                                      .toString(),
                                                                  style:
                                                                      new TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontFamily:
                                                                        'Jazeera',
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .end,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
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
                                      bottom: 5.0,
                                      left: 10.0,
                                      child: Icon(
                                        Icons.flag,
                                        color: Colors.red,
                                        size: 20,
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
                                          ],
                                        ),
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

  Widget getDiscussionAckUsers(String id) {
    return Container(
      child: FutureBuilder(
        future: _discussionsProvider.getDiscussionAckUsers(id),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          print('snapshot.data' + snapshot.data.toString());
          if (snapshot.data == null) {
            return Container(
              child: Padding(
                padding: const EdgeInsets.only(left: 80, top: 0),
                child: Center(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 40,
                      ),
                      Center(
                        child: Text(
                          "لم يطلع أحد إلى الآن على هذا النقاش",
                          style: TextStyle(
                            fontFamily: 'Jazeera',
                            fontSize: 12,
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
                          child: Card(
                            margin: const EdgeInsets.only(
                                left: 9.0, right: 9.0, top: 3.0),
                            elevation: 4.0,
                            child: Column(
                              children: [
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Expanded(
                                                  child: Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10),
                                                    child: Text(
                                                      snapshot.data[index]
                                                                  ['created_at']
                                                              .split('T')[0] +
                                                          ' ' +
                                                          snapshot.data[index]
                                                                  ['created_at']
                                                              .split('T')[1]
                                                              .split('.')[0],
                                                      style: new TextStyle(
                                                        color: Colors.black,
                                                        fontFamily: 'Jazeera',
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Icon(
                                                    Icons.timer_sharp,
                                                    color: Colors.red,
                                                    size: 15,
                                                  ),
                                                ],
                                              )),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 10),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      snapshot.data[index]
                                                          ['author'],
                                                      style: new TextStyle(
                                                        color: Colors.black,
                                                        fontFamily: 'Jazeera',
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Icon(
                                                      Icons.person,
                                                      color: Colors.red,
                                                      size: 15,
                                                    )
                                                  ],
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

  addDiscussionComment(context) {
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
            var name = _addTextController.text;
            setState(() {
              if (name.isEmpty || name.length == 0) {
                Fluttertoast.showToast(
                    msg: "لا يمكن إضافة تعليق فارغ",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              } else {
                _discussionsProvider.addDiscussionComment(
                    widget._discussionItem, name);
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

  addDiscussionAckn(context) {
    Alert(
      context: context,
      title: "  تم الإطلاع",
      style: AlertStyle(
        titleStyle: TextStyle(
          color: Colors.indigo,
          fontFamily: 'Jazeera',
          fontSize: 20,
        ),
      ),
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
          onPressed: () {
            _discussionsProvider
                .postDiscussionAcknowledge(widget._discussionItem);
            Navigator.pop(context);
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
}

String organizationName;
List<String> departmentsValues = [];
List<UserItem> accountsValues = [];

void buildDepartment() async {
  organizationName = await ShPrefs.instance.getStringValue("organization");
  departmentsValues =
      await _usersProvider.getOrganizationDepartments(organizationName);
  accountsValues = await _usersProvider.getOwnActiveOrganizationUsers();
}

class UpdateDisc extends StatefulWidget {
  @override
  _UpdateDiscState createState() => _UpdateDiscState();
}

class _UpdateDiscState extends State<UpdateDisc> {
  var deletedSwitched = deleted;
  String _fileName;
  String _path;
  Map<String, String> _paths;
  List selectedFilesNamesPaths = [];

  void _openFileExplorer() async {
    selectedFilesNamesPaths = [];
    try {
      _paths = (FilePicker.platform) as Map<String, String>;
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        // Here you can write your code

        userFiles = discussionFiles;
        userFiles.addAll(selectedFilesNamesPaths);

        setState(() {});
      });
    }

    if (!mounted) {
      // userFiles = discussionFiles;
      return;
    }

    setState(() {
      _fileName = _path != null
          ? _path.split('/').last
          : _paths != null
              ? _paths.keys.toString()
              : '...';
    });
  }

  clearTextController() {
    setState(() {
      _path = null;
      _paths = null;
      depValue = [];
      accValue = [];
      tagsValue = [];
    });
    _nameController.clear();
    _discriptionController.clear();
  }

  @override
  void initState() {
    buildDepartment();
    super.initState();
  }

  Iterable<Widget> get actorWidgets sync* {
    for (int i = 0; i < userFiles.length; i++) {
      // print(userFiles[0]['content']);
      yield Padding(
        padding: const EdgeInsets.all(2),
        child: Chip(
          key: new Key(i.toString()),
          avatar: CircleAvatar(child: Text(i.toString())),
          label: Text(userFiles[i]['name']),
          onDeleted: () {
            setState(() {
              userFiles.removeWhere((entry) {
                return entry == userFiles[i];
              });
            });
          },
        ),
      );
    }
  }

  Widget test(BuildContext context) {
    // print(userFiles.length);

    return Wrap(
      children: actorWidgets.toList(),
    );
  }

  TextEditingController _nameController =
      new TextEditingController(text: userName);
  TextEditingController _discriptionController =
      new TextEditingController(text: userDiscription);
  final TextEditingController _userTagsController = TextEditingController(
      text: userTags.toString().replaceAll(']', '').replaceAll('[', ''));
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

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

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
        '00.00Z';
    // print(deadLine);
  }

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

  retrieveData() async {
    //when you retrieve the data from the clipboard
    final data = await Clipboard.getData("text/plain");
    print(data.text);
    return data.text;
  }

  @override
  Widget build(BuildContext context) {
    buildDepartment();
    compileDateTime();
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'تعديل المناقشة',
                style: TextStyle(
                  fontFamily: 'Lalezar',
                  fontSize: 25,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Switch(
                    value: deletedSwitched,
                    onChanged: (value) async {
                      setState(() {
                        deletedSwitched = value;
                        print(deletedSwitched);
                      });
                    },
                    activeTrackColor: Colors.white,
                    activeColor: Colors.white,
                  ),
                  Icon(Icons.delete),
                ],
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
                    builder: (context) => DiscussionsDetails(userId)),
              );
            }),
      ),
      endDrawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextFormField(
                      maxLines: 2,
                      minLines: 1,
                      controller: _nameController,
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      // initialValue: 'إترك تعليقك هنا',
                      decoration: InputDecoration(
                        labelText: 'عنوان النقاش:',
                        labelStyle: TextStyle(
                            color: Colors.red,
                            fontFamily: 'Jazeera',
                            fontSize: 15),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: (text) {
                        text = _nameController.text;
                      },
                    ),
                    Builder(
                      builder: (context) => TextFormField(
                        onTap: () {},
                        textAlign: TextAlign.right,
                        maxLines: 100,
                        minLines: 1,
                        controller: _discriptionController,
                        cursorColor: Theme.of(context).colorScheme.secondary,
                        // initialValue: 'إترك تعليقك هنا',
                        decoration: InputDecoration(
                          labelText: 'الوصف:-',
                          labelStyle: TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                            fontFamily: 'Jazeera',
                          ),
                          suffixIcon: IconButton(
                              icon: Icon(
                                Icons.paste,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                _discriptionController.text =
                                    _discriptionController.text +
                                        await retrieveData();
                                // ignore: deprecated_member_use
                                Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text('past from Clipboard')));
                              }),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _userTagsController,
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      // initialValue: 'إترك تعليقك هنا',
                      decoration: InputDecoration(
                        labelText: 'العلامات:',
                        // hintText: "e.g 1,2,3,4,5",
                        labelStyle: TextStyle(
                            color: Colors.red,
                            fontFamily: 'Jazeera',
                            fontSize: 15),
                        helperText: 'e.g 1,2,3;4,5',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: (text) {
                        text = _userTagsController.text;
                      },
                    ),
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
                                    onPressed: () => _selectTime(context)),
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
                                  "${selectedDate.toLocal()}".split(' ')[0],
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
                                    onPressed: () => _selectDate(context)),
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
                                        DateTime.now().add(Duration(hours: 6)));
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
                                    selectedDate =
                                        DateTime.now().add(Duration(days: 1));
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
                                    selectedDate =
                                        DateTime.now().add(Duration(days: 3));
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
                                    selectedDate =
                                        DateTime.now().add(Duration(days: 7));
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
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 10,
                              child: MultiSelectFormField(
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
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 23,
                              child: MultiSelectFormField(
                                trailing: Icon(Icons.add_box),
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
                                  "المُستخدمين",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Jazeera',
                                    fontSize: 15,
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
                    SingleChildScrollView(
                      child: Container(
                        child: Column(
                          children: [
                            // ignore: deprecated_member_use
                            FlatButton.icon(
                              icon: Icon(
                                Icons.upload_file,
                                size: 20,
                                color: Colors.red,
                              ),
                              label: Text(
                                "إضافة ملف من الهاتف",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Jazeera',
                                ),
                              ),
                              shape: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.red, width: 2),
                              ),
                              textColor: Colors.red,
                              onPressed: () async {
                                deleteCacheDir();
                                _openFileExplorer();
                              },
                            ),
                            new SingleChildScrollView(
                              child: new Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _path != null || _paths != null
                                      ? new Container(
                                          height: 0,
                                          child: new Scrollbar(
                                              child: new ListView.separated(
                                            itemCount: _paths != null &&
                                                    _paths.isNotEmpty
                                                ? _paths.length
                                                : 1,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              // print("itembuilder index $index");

                                              final bool isMultiPath =
                                                  _paths != null &&
                                                      _paths.isNotEmpty;

                                              final String name = (isMultiPath
                                                  ? _paths.keys.toList()[index]
                                                  : _fileName ?? '...');

                                              // print("itembuilder name $name");

                                              final path = isMultiPath
                                                  ? _paths.values
                                                      .toList()[index]
                                                      .toString()
                                                  : _path;
                                              // print("itembuilder path $path");

                                              selectedFilesNamesPaths.add(
                                                  {"name": name, "path": path});

                                              return Text(
                                                name.split('.')[0],
                                                style: TextStyle(
                                                    color: Colors.red),
                                              );
                                            },
                                            separatorBuilder:
                                                (BuildContext context,
                                                        int index) =>
                                                    new Divider(),
                                          )),
                                        )
                                      : new Container(),
                                  Row(
                                    children: [],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    discussionFiles.isNotEmpty
                        ? TextFormField(
                            enabled: false,
                            cursorColor:
                                Theme.of(context).colorScheme.secondary,
                            decoration: InputDecoration(
                              labelText: 'الملفات المرفقة',
                              labelStyle: TextStyle(
                                fontFamily: 'Jazeera',
                                color: Colors.red,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                          )
                        : Row(),
                    test(context),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(width: 3),
                    Expanded(
                      child: MaterialButton(
                        onPressed: () async {
                          // print(_nameController.text);
                          // print(_discriptionController.text);
                          // print(userFiles);
                          // print(depValue);
                          // print(accValue);
                          // print('tags:' + tagsValue.toString());
                          var userTagsText = _userTagsController.text;

                          List<dynamic> fullTags2 = [];
                          fullTags2.add(userTagsText);
                          // print(fullTags2);
                          if (_nameController.text.isEmpty) {
                            Fluttertoast.showToast(
                              msg: "تاكد من البيانات جيداً",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          } else {
                            // print(selectedFilesNamesPaths);
                            await _discussionsProvider.updateDiscussion(
                                userId,
                                _nameController.text,
                                deadLine,
                                _discriptionController.text,
                                userFiles,
                                depValue,
                                accValue,
                                fullTags2,
                                deletedSwitched);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => DiscussionsDetails(userId),
                            ));
                          }
                        },
                        child: Text(
                          "تعديل",
                          style: TextStyle(
                              fontFamily: 'Jazeera',
                              color: Colors.white,
                              fontSize: 12),
                        ),
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 3),
                    Expanded(
                      child: MaterialButton(
                        onPressed: () async {
                          setState(() {
                            Navigator.pop(context);
                          });
                          _nameController.clear();
                          _discriptionController.clear();
                          selectedFilesNamesPaths.clear();
                          depValue.clear();
                          accValue.clear();
                          tagsValue.clear();
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> deleteCacheDir() async {
  final cacheDir = await getTemporaryDirectory();

  if (cacheDir.existsSync()) {
    cacheDir.deleteSync(recursive: true);
  }
}
