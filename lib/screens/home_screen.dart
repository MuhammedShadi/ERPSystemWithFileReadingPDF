import 'dart:io';
import 'dart:ui' as ui;

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/screens/login.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';

String userAccessTok = '';
LoginProvider _loginProvider = new LoginProvider();
List openFilesHistory = [];
bool setInitTunnelCheck = false;

class HomeScreen extends StatefulWidget {
  static const routName = "/HomeScreen";
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const platform = const MethodChannel('fileshare.tunneling');
  static const platformMusic = const MethodChannel('Music');

  playMusic() async {
    try {
      await platformMusic.invokeMethod('playMusic');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  stopMusic() async {
    try {
      await platformMusic.invokeMethod('stopMusic');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  _initTunnel() async {
    try {
      await platform.invokeMethod('startTunnel');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  _stopTunnel() async {
    await platform.invokeMethod('stopTunnel');
  }

  PDFDocument _doc;
  bool themeSwitched = false;
  bool _loading = false;
  bool isInit = true;
  bool arrowBool = false;
  bool hasLoggedIn = false;
  bool apiIsAlive = false;
  bool loginChecked = false;
  String _path;
  String filesRead;
  bool displayHistoryFiles;
  bool isPlayed = true;
  @override
  @mustCallSuper
  void initState() {
    secureScreen();
    // TODO: implement initState
    setState(() {
      checkUserLoggedIN();
    });
    super.initState();
    if (setInitTunnelCheck == false) {
      _initTunnel();
      setState(() {
        setInitTunnelCheck = true;
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _stopTunnel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        // printy();
        print('paused state');
        break;
      case AppLifecycleState.resumed:
        print('resumed state');
        break;
      case AppLifecycleState.inactive:
        print('inactive state');
        break;
      case AppLifecycleState.detached:
        print('detached state');
        break;
    }
  }

  // void printy() async {
  //   String value;
  //   print('Value before form java: $value');
  //   try {
  //     value = await platform.invokeMethod('Printy');
  //   } catch (e) {
  //     print(e);
  //   }
  //   print('Value form java: $value');
  // }

  Future<void> secureScreen() async {
    //print('secureScreen');
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void checkUserLoggedIN() async {
    checkHistory();
    userAccessTok = await ShPrefs.instance.getStringValue('access_token');
    if (await ShPrefs.instance.containsKey('access_token')) {
      hasLoggedIn = true;
      // setState(() {});
    } else {
      hasLoggedIn = false;
    }
    loginChecked = true;
    if (apiIsAlive == false) {
      apiIsAlive = await _loginProvider.checkAPIIsLive();
      setState(() {});
    }
    setState(() {});
  }

  void checkHistory() async {
    String historyList = await ShPrefs.instance.getStringValue('historyList');
    openFilesHistory = historyList.split(';');
    openFilesHistory.removeLast();
    if (openFilesHistory.length != 0) {
      displayHistoryFiles = true;
    } else {
      displayHistoryFiles = false;
    }
    // print(historyList);
    // print(openFilesHistory);
  }

  void _openFileExplorer() async {
    try {
      _path = (FilePicker.platform) as String;
      //openFilesHistory.add(_path);
      String historyList = await ShPrefs.instance.getStringValue('historyList');
      if (!historyList.contains(_path)) {
        historyList += _path + ';';
      }
      ShPrefs.instance.setStringValue('historyList', historyList);
      openFilesHistory = historyList.split(';');
      openFilesHistory.removeLast();
      // print(historyList);
      // print(openFilesHistory);
      // print("Path : " + _path);
      loadFromFile(new File(_path));
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
      Fluttertoast.showToast(
          msg: "$e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 6,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    if (!mounted) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loginChecked == false) {
      checkUserLoggedIN();
      setState(() {});
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PDF Viewer",
              style: TextStyle(
                fontFamily: 'Lalezar',
                fontSize: 30,
              ),
            ),
            hasLoggedIn == false && apiIsAlive == true
                ? SizedBox(
                    width: 60,
                    child: IconButton(
                      icon: Icon(
                        Icons.perm_contact_cal,
                        size: 40,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        if (await _loginProvider.checkAPIIsLive()) {
                          Navigator.of(context)
                              .pushReplacementNamed(LoginScreen.routeName);
                        }
                      },
                    ),
                  )
                : Row(),
          ],
        ),
        leading: arrowBool
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(HomeScreen.routName);
                },
              )
            : Row(),
      ),
      endDrawer: hasLoggedIn && apiIsAlive ? AppDrawer() : null,
      body: Container(
        color: Colors.red,
        padding: const EdgeInsets.all(15),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: isInit
            ? SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(0, 80, 0, 0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 60,
                        color: Colors.red,
                      ),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    // ignore: deprecated_member_use
                    FlatButton.icon(
                      icon: Icon(
                        Icons.upload_file,
                        size: 40,
                      ),
                      label: Text(
                        "PDF فتح ملف ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'Jazeera'),
                      ),
                      shape: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(12),
                      textColor: Colors.white,
                      onPressed: () async {
                        _openFileExplorer();
                        arrowBool = true;
                      },
                    ), // ignore: deprecated_member_use
                    // ignore: deprecated_member_use
                    // FlatButton.icon(
                    //   icon: Icon(
                    //     Icons.stop_circle_outlined,
                    //     size: 40,
                    //   ),
                    //   label: Text(
                    //     "Start VPN",
                    //     style: TextStyle(
                    //         fontWeight: FontWeight.bold,
                    //         fontSize: 20,
                    //         fontFamily: 'Jazeera'),
                    //   ),
                    //   shape: OutlineInputBorder(
                    //     borderRadius: BorderRadius.circular(10),
                    //     borderSide: BorderSide(color: Colors.white, width: 2),
                    //   ),
                    //   padding: const EdgeInsets.all(12),
                    //   textColor: Colors.white,
                    //   onPressed: () async {
                    //     _initTunnel();
                    //   },
                    // ),
                    // FlatButton.icon(
                    //   icon: Icon(
                    //     Icons.stop_circle_outlined,
                    //     size: 40,
                    //   ),
                    //   label: Text(
                    //     "Stop VPN",
                    //     style: TextStyle(
                    //         fontWeight: FontWeight.bold,
                    //         fontSize: 20,
                    //         fontFamily: 'Jazeera'),
                    //   ),
                    //   shape: OutlineInputBorder(
                    //     borderRadius: BorderRadius.circular(10),
                    //     borderSide: BorderSide(color: Colors.white, width: 2),
                    //   ),
                    //   padding: const EdgeInsets.all(12),
                    //   textColor: Colors.white,
                    //   onPressed: () async {
                    //     _stopTunnel();
                    //   },
                    // ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isPlayed
                            ? IconButton(
                                color: Colors.white,
                                iconSize: 40,
                                icon: Icon(Icons.play_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    isPlayed = false;
                                    playMusic();
                                  });
                                })
                            : IconButton(
                                color: Colors.white,
                                iconSize: 40,
                                icon: Icon(Icons.stop_circle_outlined),
                                onPressed: () {
                                  setState(() {
                                    isPlayed = true;
                                    stopMusic();
                                  });
                                }),
                      ],
                    ),
                    SizedBox(height: 50),
                    if (displayHistoryFiles == true)
                      Column(
                        children: [
                          Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: Row(
                              children: [
                                IconButton(
                                    icon: Icon(
                                      Icons.cleaning_services,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        ShPrefs.instance
                                            .setStringValue('historyList', '');
                                        openFilesHistory = [];
                                        displayHistoryFiles = false;
                                        Fluttertoast.showToast(
                                            msg:
                                                "تم مسح جميع الملفات من الذاكرة",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Colors.green,
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                        _loginProvider.deleteCacheAndAppDir();
                                        print('delete');
                                      });
                                    }),
                                Directionality(
                                    textDirection: ui.TextDirection.rtl,
                                    child: Container(
                                        child: Text(
                                      'آخر الملفات :',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          fontFamily: 'Jazeera'),
                                      textAlign: TextAlign.start,
                                    ))),
                              ],
                            ),
                          ),
                          Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: InkWell(
                              child: SingleChildScrollView(
                                child: Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  child: ListView.separated(
                                    itemCount: openFilesHistory.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      // print("itembuilder index $index " +
                                      //     openFilesHistory[index].toString());
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 4, right: 40),
                                        child: Container(
                                          height: 35,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: Colors.red.shade400),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                  icon: Icon(
                                                    Icons.remove_circle_sharp,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed: () async {
                                                    _loginProvider
                                                        .deleteCacheAndAppDir();
                                                    setState(() {
                                                      ShPrefs.instance
                                                          .removeValue(
                                                              'historyList');
                                                      openFilesHistory.remove(
                                                          openFilesHistory[
                                                              index]);
                                                      if (openFilesHistory
                                                              .length !=
                                                          0) {
                                                        Fluttertoast.showToast(
                                                            msg:
                                                                "تم مسح الملف ${openFilesHistory[index].split('/').last} من الذاكرة",
                                                            toastLength: Toast
                                                                .LENGTH_SHORT,
                                                            gravity:
                                                                ToastGravity
                                                                    .BOTTOM,
                                                            timeInSecForIosWeb:
                                                                1,
                                                            backgroundColor:
                                                                Colors.green,
                                                            textColor:
                                                                Colors.white,
                                                            fontSize: 16.0);
                                                      } else {
                                                        setState(() {
                                                          displayHistoryFiles =
                                                              false;
                                                        });
                                                        Fluttertoast.showToast(
                                                            msg:
                                                                "تم مسح جميع الملفات من الذاكرة",
                                                            toastLength: Toast
                                                                .LENGTH_SHORT,
                                                            gravity:
                                                                ToastGravity
                                                                    .BOTTOM,
                                                            timeInSecForIosWeb:
                                                                1,
                                                            backgroundColor:
                                                                Colors.green,
                                                            textColor:
                                                                Colors.white,
                                                            fontSize: 16.0);
                                                      }
                                                    });
                                                    print('delete');
                                                  }),
                                              Flexible(
                                                child: InkWell(
                                                  child: Wrap(
                                                    direction: Axis.vertical,
                                                    children: [
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                2 +
                                                            20,
                                                        child: Text(
                                                          openFilesHistory[
                                                                  index]
                                                              .split('/')
                                                              .last,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onTap: () {
                                                    loadFromFile(new File(
                                                        openFilesHistory[
                                                            index]));
                                                    arrowBool = true;
                                                    print('open');
                                                  },
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            new Row(),
                                  ),
                                ),
                              ),
                              onTap: () {
                                loadFromFile(new File(filesRead));
                                arrowBool = true;
                                print('open');
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      Row(),
                  ],
                ),
              )
            : _loading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                :
                // : PDF.file(_doc2),
                PDFViewer(
                    document: _doc,
                    showPicker: true,
                  ),
      ),
    );
  }

  loadFromFile(File nameFile) async {
    setState(() {
      isInit = false;
      _loading = true;
    });
    _doc = await PDFDocument.fromFile(nameFile);
    print(nameFile.path);
    print(_doc);
    setState(() {
      _loading = false;
    });
  }
}
