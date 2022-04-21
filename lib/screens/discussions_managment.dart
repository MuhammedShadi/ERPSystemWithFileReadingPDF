import 'dart:async';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:pagination_view/pagination_view.dart';
import 'package:pdfviewer/models/discussion_item.dart';
import 'package:pdfviewer/models/new_discussion.dart';
import 'package:pdfviewer/models/user_item.dart';
import 'package:pdfviewer/providers/discussions_provider.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/providers/users_provider.dart';
import 'package:pdfviewer/screens/discussions_details.dart';
import 'package:pdfviewer/screens/search_screen.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:smart_select/smart_select.dart';

Timer timer;
DiscussionsProvider _discussionsProvider = new DiscussionsProvider();

bool themeSwitched = false;
bool makeMeTrue = false;
UsersProvider _usersProvider = new UsersProvider();
LoginProvider _loginProvider = new LoginProvider();
bool hasCreateDiscussionsPermission;
bool hasManageDiscussionPermissions = false;
bool permissionsHasBeenSet = false;
bool _validate = false;
List<dynamic> userFiles = [];
dynamic themeColor() {
  if (themeSwitched) {
    return Colors.grey[850];
  } else {}
}

String deadLine = '';

class DiscussionsManagement extends StatefulWidget {
  static const routName = '/discussionsManagement';
  @override
  _DiscussionsManagementState createState() => _DiscussionsManagementState();
}

class _DiscussionsManagementState extends State<DiscussionsManagement> {
  Future<void> secureScreen() async {
    // print('secureScreen');
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  void initState() {
    secureScreen();
    checkDiscussionsPermissions();
    super.initState();
    page = 0;
    paginationViewType = PaginationViewType.listView;
    key = GlobalKey<PaginationViewState>();
    super.initState();
    timer = Timer.periodic(Duration(minutes: 5), (Timer t) {
      print('delete cache and app dir');
      _loginProvider.deleteCacheAndAppDir();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<Null> checkDiscussionsPermissions() async {
    hasCreateDiscussionsPermission = false;
    if (await ShPrefs.instance.containsKey('permissions')) {
      String permissionsFromShPre =
          await ShPrefs.instance.getStringValue('permissions');
      //print(permissionsFromShPre);
      permissionsHasBeenSet = true;
      hasCreateDiscussionsPermission =
          permissionsFromShPre.contains("create-discussion");
      // print(hasCreateDiscussionsPermission);
      hasManageDiscussionPermissions =
          permissionsFromShPre.contains('view::acked|dead|deleted::discussion');
      setState(() {});
    }
  }

  int page;
  PaginationViewType paginationViewType;
  GlobalKey<PaginationViewState> key;

  @override
  Widget build(BuildContext context) {
    // print('aa' + permissionsHasBeenSet.toString());
    if (permissionsHasBeenSet == false) {
      checkDiscussionsPermissions();
    }
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
                  "إدارة المناقشات",
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
          leading: hasCreateDiscussionsPermission == true
              ? IconButton(
                  icon: Icon(
                    Icons.add_comment,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await buildDepartment();
                    Navigator.push(
                      context,
                      new MaterialPageRoute(
                        builder: (context) => AddNewDiscussions(),
                      ),
                    );
                  },
                )
              : Row()),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: getDiscussionsData(),
      floatingActionButton: hasManageDiscussionPermissions == true
          ? Padding(
              padding: const EdgeInsets.only(right: 300.0),
              child: FloatingActionButton(
                onPressed: () {
                  getFilteredData(context);
                },
                tooltip: 'Search',
                child: Icon(Icons.filter_list),
              ),
            )
          : Row(),
    );
  }

  Widget getDiscussionsData() {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      clipBehavior: Clip.hardEdge,
      child: Container(
        color: Colors.black12,
        child: PaginationView<DiscussionItem>(
          key: key,
          paginationViewType: paginationViewType,
          itemBuilder: (BuildContext context, DiscussionItem disc, int index) =>
              (paginationViewType == PaginationViewType.listView)
                  ? InkWell(
                      onTap: () async {
                        ShPrefs.instance.setStringValue(
                            'deletedValue', disc.deleted.toString());
                        // print(await ShPrefs.instance
                        //     .getStringValue('deletedValue'));
                        Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) =>
                                  DiscussionsDetails(disc.id)),
                        );
                      },
                      child: Stack(children: [
                        disc.deleted == true
                            ? Card(
                                color: Colors.red.shade50,
                                margin: const EdgeInsets.only(
                                    left: 5.0,
                                    right: 5.0,
                                    bottom: 10.0,
                                    top: 3.0),
                                elevation: 4.0,
                                child: Column(
                                  children: [
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.comment,
                                          size: 35,
                                          color: themeSwitched
                                              ? Colors.white
                                              : Colors.redAccent,
                                        ),
                                        disc.files.length == 0
                                            ? Row()
                                            : Stack(
                                                children: [
                                                  Icon(
                                                    Icons.attach_file,
                                                    size: 30,
                                                    color: themeSwitched
                                                        ? Colors.white
                                                        : Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 35),
                                                  Positioned(
                                                    bottom: 0.0,
                                                    right: 0.0,
                                                    child: Text(
                                                      disc.files.length
                                                          .toString(),
                                                      style: TextStyle(
                                                        color: themeSwitched
                                                            ? Colors.white
                                                            : Colors.redAccent,
                                                        fontFamily: 'Jazeera',
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Row(
                                                // mainAxisAlignment:
                                                //     MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.name,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.author,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.createdAt.split(
                                                                  "T")[0] +
                                                              '  ' +
                                                              disc.createdAt
                                                                  .split("T")[1]
                                                                  .split(
                                                                      '.')[0],
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                  ],
                                ),
                              )
                            : Card(
                                color: themeColor(),
                                margin: const EdgeInsets.only(
                                    left: 5.0,
                                    right: 5.0,
                                    bottom: 10.0,
                                    top: 3.0),
                                elevation: 4.0,
                                child: Column(
                                  children: [
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.comment,
                                          size: 35,
                                          color: themeSwitched
                                              ? Colors.white
                                              : Colors.redAccent,
                                        ),
                                        disc.files.length == 0
                                            ? Row()
                                            : Stack(
                                                children: [
                                                  Icon(
                                                    Icons.attach_file,
                                                    size: 30,
                                                    color: themeSwitched
                                                        ? Colors.white
                                                        : Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 35),
                                                  Positioned(
                                                    bottom: 0.0,
                                                    right: 0.0,
                                                    child: Text(
                                                      disc.files.length
                                                          .toString(),
                                                      style: TextStyle(
                                                        color: themeSwitched
                                                            ? Colors.white
                                                            : Colors.redAccent,
                                                        fontFamily: 'Jazeera',
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Row(
                                                // mainAxisAlignment:
                                                //     MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.name,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.author,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.createdAt.split(
                                                                  "T")[0] +
                                                              '  ' +
                                                              disc.createdAt
                                                                  .split("T")[1]
                                                                  .split(
                                                                      '.')[0],
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontFamily:
                                                                'Jazeera',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                  ],
                                ),
                              ),
                        disc.deleted == true
                            ? Positioned(
                                bottom: 10.0,
                                left: 5.0,
                                child: Icon(Icons.flag, color: Colors.red),
                              )
                            : Row(),
                      ]),
                    )
                  : Stack(children: [
                      disc.deleted == true
                          ? Card(
                              color: Colors.white70,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) =>
                                            DiscussionsDetails(disc.id)),
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
                                                    Icons.comment,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.name,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.author,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.createdAt.split(
                                                                  "T")[0] +
                                                              '  ' +
                                                              disc.createdAt
                                                                  .split("T")[1]
                                                                  .split(
                                                                      '.')[0],
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
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
                            )
                          : Card(
                              color: themeColor(),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) =>
                                            DiscussionsDetails(disc.id)),
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
                                                    Icons.comment,
                                                    size: 40,
                                                    color: themeSwitched
                                                        ? Colors.white
                                                        : Colors.redAccent,
                                                  ),
                                                  disc.files.length == 0
                                                      ? Row()
                                                      : Stack(
                                                          children: [
                                                            Icon(
                                                              Icons.attach_file,
                                                              size: 30,
                                                              color: themeSwitched
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .redAccent,
                                                            ),
                                                            SizedBox(width: 35),
                                                            Positioned(
                                                              bottom: 0.0,
                                                              right: 0.0,
                                                              child: Text(
                                                                disc.files
                                                                    .length
                                                                    .toString(),
                                                                style:
                                                                    TextStyle(
                                                                  color: themeSwitched
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .redAccent,
                                                                  fontFamily:
                                                                      'Jazeera',
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.name,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.author,
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Container(
                                                        child: Text(
                                                          disc.createdAt.split(
                                                                  "T")[0] +
                                                              '  ' +
                                                              disc.createdAt
                                                                  .split("T")[1]
                                                                  .split(
                                                                      '.')[0],
                                                          style: new TextStyle(
                                                            color: themeSwitched
                                                                ? Colors.white
                                                                : Colors.black,
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
                      disc.deleted == true
                          ? Positioned(
                              bottom: 10.0,
                              left: 5.0,
                              child: Icon(Icons.flag, color: Colors.red),
                            )
                          : Row(),
                    ]),
          pageFetch: pageFetch,
          //pageRefresh: pageRefresh,
          pullToRefresh: true,
          onError: (dynamic error) => Center(
            child: Text('Some error occurred' + error.toString()),
          ),
          onEmpty: Center(
            child: Text(
              'لا توجد مناقشات ',
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

  Future<List<DiscussionItem>> pageFetch(int offset) async {
    page++;
    // print('test here!');
    final List<DiscussionItem> nextDiscList =
        await _discussionsProvider.getDiscussionsP(pageNum: page);
    await Future<List<DiscussionItem>>.delayed(Duration(milliseconds: 30));
    var maxPage = 0;
    String maxPageS = await ShPrefs.instance.getStringValue('discussionPages');

    if (maxPageS != "") {
      maxPage = int.parse(maxPageS);
    }
    return page == maxPage + 1 ? [] : nextDiscList;
  }

  Future<List<DiscussionItem>> pageRefresh(int offset) async {
    page = 0;
    return pageFetch(offset);
  }

  getFilteredData(context) async {
    final TextEditingController _titleFilteredController =
        TextEditingController();
    final TextEditingController _discussionNameFilteredController =
        TextEditingController();
    final TextEditingController _tagsFilteredController =
        TextEditingController();
    await buildDepartment();
    List departmentsOptions = List.generate(
        departmentsValues.length,
        (index) => {
              "display": departmentsValues[index],
              "value": departmentsValues[index]
            });
    List accountsOptions = List.generate(
        accountsValues.length,
        (index) => {
              "display": accountsValues[index].name,
              "value": accountsValues[index].name
            });

    List<S2Choice<String>> deletedOptions = [
      S2Choice<String>(value: 'null', title: 'عرض الكل'),
      S2Choice<String>(value: 'true', title: 'عرض المحذوف'),
      S2Choice<String>(value: 'false', title: 'عرض الفعال'),
    ];
    List<S2Choice<String>> acknOptions = [
      S2Choice<String>(value: 'true', title: 'مُفعل'),
      S2Choice<String>(value: 'false', title: 'غير مُفعل'),
    ];

    List<dynamic> accountValue = [];
    List<dynamic> depValue = [];
    String depParam = '';
    String accountUsersParam = '';
    String acknDiscParam = '';
    String deletedParam = '';
    filteredValues() {
      for (int i = 0; i < depValue.length; i++) {
        depParam += "&departments=${Uri.encodeFull(depValue[i].toString())}";
      }
      for (int i = 0; i < accountValue.length; i++) {
        accountUsersParam +=
            "&users=${Uri.encodeFull(accountValue[i].toString())}";
      }
      ShPrefs.instance.setStringValue('discDepartment', depParam);
      ShPrefs.instance.setStringValue('accountUsers', accountUsersParam);
      ShPrefs.instance.setStringValue('ackn', acknDiscParam);
      ShPrefs.instance.setStringValue('deletedBool', deletedParam);
      ShPrefs.instance.setStringValue('titles', _titleFilteredController.text);
      ShPrefs.instance.setStringValue(
          'discussionNames', _discussionNameFilteredController.text);
      ShPrefs.instance.setStringValue('discTags', _tagsFilteredController.text);
    }

    clearValues() {
      _titleFilteredController.clear();
      _discussionNameFilteredController.clear();
      _tagsFilteredController.clear();
      depValue = [];
      accountValue = [];
    }

    removeValues() {
      ShPrefs.instance.removeValue('discDepartment');
      ShPrefs.instance.removeValue('accountUsers');
      ShPrefs.instance.removeValue('titles');
      ShPrefs.instance.removeValue('discussionNames');
      ShPrefs.instance.removeValue('discTags');
      ShPrefs.instance.removeValue('ackn');
      ShPrefs.instance.removeValue('deletedBool');
    }

    Alert(
      context: context,
      title: " بحث عن نقاش",
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
                  controller: _titleFilteredController,
                  cursorColor: Theme.of(context).colorScheme.secondary,
                  // initialValue: 'إترك تعليقك هنا',
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'العنوان',
                    labelStyle: TextStyle(
                      color: Color(0xFF6200EE),
                    ),
                    helperText: 'عدد الأحرف',
                    suffixIcon: Icon(
                      Icons.title,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6200EE)),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _discussionNameFilteredController,
                  cursorColor: Theme.of(context).colorScheme.secondary,
                  // initialValue: 'إترك تعليقك هنا',
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'إسم النقاش',
                    labelStyle: TextStyle(
                      color: Color(0xFF6200EE),
                    ),
                    helperText: 'عدد الأحرف',
                    suffixIcon: Icon(
                      Icons.content_paste,
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
                      // print(depValue);
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
                      // print(accountValue);
                    });
                  },
                ),
                SmartSelect<String>.single(
                  title: 'عرض النقاش',
                  value: deletedParam,
                  choiceItems: deletedOptions,
                  onChange: (state) => setState(() {
                    deletedParam = state.value;
                    // print(deletedParam);
                  }),
                  placeholder: ' حدد عنصر للبحث',
                  choiceStyle: S2ChoiceStyle(
                    color: Colors.blue,
                    titleStyle: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Jazeera',
                      fontSize: 15,
                    ),
                    subtitleStyle: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Jazeera',
                      fontSize: 15,
                    ),
                  ),
                ),
                SmartSelect<String>.single(
                  title: 'الإطلاع',
                  value: acknDiscParam,
                  choiceItems: acknOptions,
                  onChange: (state) => setState(() {
                    acknDiscParam = state.value;
                    // print(acknDiscParam);
                  }),
                  placeholder: 'هل الإطلاع مُفعل أم لا ؟',
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
                TextFormField(
                  controller: _tagsFilteredController,
                  cursorColor: Theme.of(context).colorScheme.secondary,
                  // initialValue: 'إترك تعليقك هنا',
                  decoration: InputDecoration(
                    labelText: 'الإشارات',
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
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/discussionsManagement', (Route<dynamic> route) => false);
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
              // Navigator.of(context)
              //     .pushReplacementNamed("/discussionsManagement");
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/discussionsManagement', (Route<dynamic> route) => false);
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
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/discussionsManagement', (Route<dynamic> route) => false);
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

class AddNewDiscussions extends StatefulWidget {
  @override
  _AddNewDiscussionsState createState() => _AddNewDiscussionsState();
}

class _AddNewDiscussionsState extends State<AddNewDiscussions> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _discriptionController = new TextEditingController();
  final TextEditingController _userTagsController = TextEditingController();
  List<dynamic> depValue = [];
  List<dynamic> accValue = [];
  List selectedFiles = [];
  List selectedFilesNamesPaths = [];
  String _fileName;
  String _path;
  Map<String, String> _paths;
  String filesNames = '';
  String testDeps = '';
  List<dynamic> fullTags2 = [];
  var isDisable = false;
  bool isAdded = false;
  Color colorAddNewDisc = Colors.green;

  Future<void> disableSecureScreen() async {
    // print('secureScreen');
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void _openFileExplorer() async {
    selectedFilesNamesPaths = [];
    try {
      _paths = (FilePicker.platform) as Map<String, String>;
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        // Here you can write your code
        //def1 no old files
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
      selectedFilesNamesPaths = [];
      userFiles.clear();
    });
    _nameController.clear();
    _discriptionController.clear();
    _userTagsController.clear();
  }

  @override
  void initState() {
    //buildDepartment();
    disableSecureScreen();
    prepareDep();
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

  Widget drawFilesNameSelected(BuildContext context) {
    return Wrap(
      children: actorWidgets.toList(),
    );
  }

  prepareDep() async {
    await buildDepartment();
  }

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

  @override
  Widget build(BuildContext context) {
    compileDateTime();
    setState(() {
      _nameController.text.isEmpty ? _validate = true : _validate = false;
    });

    return Scaffold(
      appBar: AppBar(
        // ignore: deprecated_member_use
        brightness: themeSwitched ? Brightness.light : Brightness.dark,
        elevation: 0,
        backgroundColor: themeColor(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                "إضافة مناقشة جديدة",
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
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context)
                .pushReplacementNamed("/discussionsManagement");
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
                            controller: _nameController,
                            cursorColor: Theme.of(context).colorScheme.secondary,
                            // initialValue: 'إترك تعليقك هنا',
                            decoration: InputDecoration(
                              errorText:
                                  _validate ? 'العنوان لا يكون فارغاً' : null,
                              labelText: 'عنوان النقاش:',
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
                              text = _nameController.text;
                            },
                          ),
                          Builder(
                            builder: (context) => TextField(
                              enableInteractiveSelection: true,
                              toolbarOptions: ToolbarOptions(
                                paste: true,
                                cut: true,
                                copy: true,
                                selectAll: true,
                              ),

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
                                      Scaffold.of(context).showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('past from Clipboard')));
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
                              helperText: 'e.g 1,2,3,4,5',
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
                          // ignore: deprecated_member_use
                          Divider(),
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
                                      borderSide: BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    textColor: Colors.red,
                                    onPressed: () async {
                                      deleteCacheDir();
                                      _openFileExplorer();
                                    },
                                  ),
                                  new SingleChildScrollView(
                                    child: new Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        _path != null || _paths != null
                                            ? new Container(
                                                height: 0,
                                                child: new Scrollbar(
                                                    child:
                                                        new ListView.separated(
                                                  itemCount: _paths != null &&
                                                          _paths.isNotEmpty
                                                      ? _paths.length
                                                      : 1,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    final bool isMultiPath =
                                                        _paths != null &&
                                                            _paths.isNotEmpty;
                                                    final String name =
                                                        (isMultiPath
                                                            ? _paths.keys
                                                                .toList()[index]
                                                            : _fileName ??
                                                                '...');
                                                    final path = isMultiPath
                                                        ? _paths.values
                                                            .toList()[index]
                                                            .toString()
                                                        : _path;
                                                    selectedFilesNamesPaths
                                                        .add({
                                                      "name": name,
                                                      "path": path
                                                    });
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
                          drawFilesNameSelected(context),
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
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: MaterialButton(
                                  onPressed: isDisable
                                      ? () => () {}
                                      : () async {
                                          var userTagsText =
                                              _userTagsController.text;
                                          fullTags2.add(userTagsText);
                                          CreateDiscussionItem
                                              _newDiscussionItem =
                                              CreateDiscussionItem(
                                                  _nameController.text,
                                                  deadLine,
                                                  _discriptionController.text,
                                                  userFiles,
                                                  depValue,
                                                  accValue,
                                                  fullTags2);

                                          if (_nameController.text.isEmpty) {
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
                                              if (await _discussionsProvider
                                                  .addNewDiscussion(
                                                      _newDiscussionItem)) {
                                                clearTextController();
                                                await Navigator.of(context)
                                                    .pushReplacementNamed(
                                                        "/discussionsManagement");
                                              }
                                              setState(() {});
                                            });

                                            // if () {
                                            // }
                                          }
                                        },
                                  child: Text(
                                    "إضافة المناقشة ",
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
