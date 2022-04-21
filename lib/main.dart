import 'package:flutter/material.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/screens/discussions_details.dart';
import 'package:pdfviewer/screens/discussions_managment.dart';
import 'package:pdfviewer/screens/home_screen.dart';
import 'package:pdfviewer/screens/login.dart';
import 'package:pdfviewer/screens/message_details.dart';
import 'package:pdfviewer/screens/messages_managment.dart';
import 'package:pdfviewer/screens/pdf_viewer_screen.dart';
import 'package:pdfviewer/screens/resetpassword.dart';
import 'package:pdfviewer/screens/user_details.dart';
import 'package:pdfviewer/screens/users_management.dart';
import 'package:splashscreen/splashscreen.dart';

String _userItem;
String _discussionItem;
String _messageItem;
LoginProvider _loginProvider = new LoginProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String accessTkn = await ShPrefs.instance.getStringValue("access_token");
  Widget splashScreen() {
    return new SplashScreen(
      seconds: 1,
      navigateAfterSeconds: _loginProvider.checkAPIIsLive() == true
          ? accessTkn == ""
              ? LoginScreen()
              : DiscussionsManagement()
          : _loginProvider.checkIsSwitchedValue() == true
              ? HomeScreen()
              : HomeScreen(),
      title: new Text(
        'أهلاً و سهلاً بكم ',
        style:
            TextStyle(fontFamily: 'Jazeera', color: Colors.white, fontSize: 20),
      ),
      loadingText: Text("من فضلك إنتظر",
          style: TextStyle(
              fontFamily: 'Jazeera', color: Colors.white, fontSize: 20)),
      gradientBackground: new LinearGradient(
          colors: [Colors.redAccent, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      styleTextUnderTheLoader: new TextStyle(),
      photoSize: 100.0,
      loaderColor: Colors.white,
    );
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: splashScreen(),
      routes: {
        LoginScreen.routeName: (ctx) => LoginScreen(),
        ReSetPassWord.routeName: (ctx) => ReSetPassWord(),
        UserManagement.routName: (ctx) => UserManagement(),
        DiscussionsManagement.routName: (ctx) => DiscussionsManagement(),
        DiscussionsDetails.routName: (ctx) =>
            DiscussionsDetails(_discussionItem),
        UserDetails.routName: (ctx) => UserDetails(_userItem),
        HomeScreen.routName: (ctx) => HomeScreen(),
        PdfViewerScreen.routName: (ctx) => PdfViewerScreen(_discussionItem),
        MessagesManagment.routName: (ctx) => MessagesManagment(),
        MessageDetails.routName: (ctx) => MessageDetails(_messageItem),
      },
    ),
  );
}
