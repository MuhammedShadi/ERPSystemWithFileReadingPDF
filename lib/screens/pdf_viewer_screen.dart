// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/widgets/app_drawer.dart';

bool _loading = false;
bool isInit = true;
// PDFDocument _doc;
String _doc2;

String filePath = '';
bool _disposed = false;
Completer<PDFViewController> _controller = Completer<PDFViewController>();
UniqueKey pdfViewerKey = UniqueKey();

class PdfViewerScreen extends StatefulWidget {
  static const routName = '/PdfViewerScreen';
  final String _pdfViewerItem;
  PdfViewerScreen(this._pdfViewerItem);
  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool themeSwitched = false;
  bool isInit = true;

  dynamic themeColor() {
    if (themeSwitched) {
      return Colors.grey[850];
    } else {}
  }

  checkFilePath() async {
    filePath = await ShPrefs.instance.getStringValue('filetoviewpath');
    print("before:" + _doc2.toString());
    if (!mounted) return;
    _doc2 = filePath;
    // _doc = await PDFDocument.fromFile(new File(filePath));
    print(_doc2);
    if (!mounted) return;
    _loading = true;
    print("after:" + _doc2.toString());
    //print('from viewer' + filePath);
    if (!_disposed) {
      setState(() {
        //print('set state called');
      });
    }
  }

  @override
  void dispose() {
    //print('before dispose called');
    _disposed = true;
    super.dispose();
    //print('after dispose called');
  }

  @override
  @mustCallSuper
  void initState() {
    // TODO: implement initState
    checkFilePath();
    super.initState();
  }

  bool stopBuild = true;
  bool stopBuild2 = false;
  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      if (stopBuild) {
        setState(() {
          _controller = Completer<PDFViewController>();
          pdfViewerKey = UniqueKey();
          stopBuild = false;
          stopBuild2 = true;
        });
      }
    }
    if (!isLandscape) {
      if (stopBuild2) {
        setState(() {
          _controller = Completer<PDFViewController>();
          pdfViewerKey = UniqueKey();
          stopBuild2 = false;
          stopBuild = true;
        });
      }
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        brightness: themeSwitched ? Brightness.light : Brightness.dark,
        backgroundColor: themeColor(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'عرض الملف',
                style: TextStyle(
                  fontFamily: 'Jazeera',
                  // color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, false);
            }),
      ),
      endDrawer: AppDrawer(),
      backgroundColor: themeColor(),
      body: getDisc(widget._pdfViewerItem),
    );
  }

  Widget getDisc(String discId) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: MediaQuery.of(context).size.height - 100,
          child: _loading == true
              ? _doc2 == null
                  ? Center(
                      child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 100),
                          child: Text(
                            'حاول إعادة فتح الملف مرة أخرى ',
                            style: TextStyle(
                              fontFamily: 'Jazeera',
                              // color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ))
                  : PDFView(
                      key: pdfViewerKey,
                      filePath: _doc2,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageFling: false,
                      onRender: (_pages) {
                        setState(() {});
                      },
                      onError: (error) {
                        Fluttertoast.showToast(
                          msg: error.toString(),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.TOP_RIGHT,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.grey,
                          textColor: Colors.black,
                          fontSize: 10.0,
                        );
                      },
                      onPageError: (page, error) {
                        Fluttertoast.showToast(
                          msg: error.toString(),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.TOP_RIGHT,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.grey,
                          textColor: Colors.black,
                          fontSize: 10.0,
                        );
                      },
                      onViewCreated:
                          (PDFViewController pdfViewController) async {
                        _controller.complete(pdfViewController);
                      },
                      onPageChanged: (int page, int total) {
                        //print('page change: $page/$total');
                        Fluttertoast.showToast(
                          msg: '${page + 1}/${total + 1}',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.TOP_RIGHT,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.grey,
                          textColor: Colors.black,
                          fontSize: 8.0,
                        );
                      },
                    )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
