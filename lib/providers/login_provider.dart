import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';
import 'package:pdfviewer/screens/home_screen.dart';

var apiUrl = "https://share.i.wdex.email/api/v1";

var _dio = Dio();
var errorCode = '';

class LoginProvider {
  loginFirstTime(String username, String password) async {
    try {
      Response response = await _dio.post(apiUrl + '/auth/tokens',
          data: {
            "username": username,
            "password": password,
            "grant_type": "password",
          },
          options: Options(headers: {
            "accept": "application/json",
          }));
      // print(response.data);
      // print(response.statusCode);
      if (response.statusCode == 200) {
        ShPrefs.instance.setStringValue('userName', username);
        Fluttertoast.showToast(
          msg: "تم التسجيل مرحباً بك",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        //if request sucess
        if (response.data['access_token'] != null) {
          await ShPrefs.instance
              .setStringValue('access_token', response.data['access_token']);
        }
        if (response.data['refresh_access_token'] != null) {
          await ShPrefs.instance.setStringValue(
              'refresh_access_token', response.data['refresh_access_token']);
        }
        ShPrefs.instance.setStringValue(
            "permissions",
            response.data["permissions"]
                .toString()
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(' ', ''));
        ShPrefs.instance.setStringValue('userName', username);
        ShPrefs.instance.setStringValue('email', response.data['email']);
        ShPrefs.instance.setStringValue(
            'departments', response.data['departments'].toString());
        ShPrefs.instance
            .setStringValue('hierarchy', response.data['hierarchy'].toString());
        ShPrefs.instance.setStringValue(
            "departments",
            response.data['departments']
                .toString()
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(' ', ''));
        ShPrefs.instance
            .setStringValue('organization', response.data['organization']);
        ShPrefs.instance
            .setStringValue('accountType', response.data['account_type']);
        ShPrefs.instance
            .setStringValue('active', response.data['active'].toString());
        // print(await ShPrefs.instance.getStringValue('active'));
        return true;
      }
    } on DioError catch (e) {
      print('logig error ' + e.toString());
      print(e.response.statusCode);
      if (e.response.statusCode == 400) {
        //if API not found
        Fluttertoast.showToast(
            msg: "الخدمة غير متاحة حاليا حاول لاحقا",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
      if (e.response.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "من فضلك تأكد من إسم المستخدم و كلمة المرور",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
      if (e.response.statusCode == 403) {
        Fluttertoast.showToast(
            msg: '${e.response}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
      if (e.response.statusCode == 422) {
        Fluttertoast.showToast(
            msg: "Invalid token/header",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
      if (e.response.statusCode == 404) {
        errorCode = e.response.statusCode.toString();
        print('404');
      } else {
        Fluttertoast.showToast(
          msg: "${e.response.statusMessage}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      return false;
    }
    return false;
  }

  checkAPIIsLive() async {
    try {
      Dio _dio;
      Response response = await _dio.get(apiUrl + '/');
      if (response.statusCode != 404) {
        return true;
      } else {
        deleteCacheAndAppDir();
        return false;
      }
    } on DioError catch (e) {
      print(e.response.statusCode);
      deleteCacheAndAppDir();
      return false;
    }
  }

  // Future<_dio> getApiLogin() async {
  //   __dio.interceptors.clear();
  //   __dio.interceptors.add(InterceptorsWrapper(
  //       onRequest: (Future<RequestOptions> options) async {
  //         options.headers["Accept"] = 'application/json';
  //         return options;
  //       },
  //       onResponse: (Response response) {
  //         return response; // continue
  //       },
  //       onError: (_dioError error) async {}));
  //   return __dio;
  // }
  //
  // Future<_dio> getApiClient() async {
  //   var token = await ShPrefs.instance.getStringValue('access_token');
  //   // print(token);
  //   __dio.interceptors.clear();
  //   __dio.interceptors
  //       .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
  //     // Do something before request is sent
  //     options.headers["Authorization"] = "Bearer " + token;
  //     options.headers["Accept"] = 'application/json';
  //     return options;
  //   }, onResponse: (Response response) {
  //     // Do something with response data
  //     return response; // continue
  //   }, onError: (_dioError error) async {
  //     // Do something with response error
  //     if (error.response?.statusCode == 401) {
  //       // print("401 detetcted");
  //       // ignore: deprecated_member_use
  //       __dio.interceptors.requestLock.lock();
  //       __dio.interceptors.responseLock.lock();
  //       RequestOptions options = error.response.request;
  //       token = await refrshToken();
  //       // print(token);
  //       if (token != null) {
  //         print("401 detetcted &  token not empty");
  //         // print(token);
  //         await ShPrefs.instance.setStringValue('access_token', token);
  //         // print(token);
  //         __dio.options.headers["Authorization"] = "Bearer " + token;
  //         __dio.interceptors.requestLock.unlock();
  //         __dio.interceptors.responseLock.unlock();
  //         return __dio.request(options.path, options: options);
  //       } else {
  //         // print("401 detetcted & token empty");
  //         // print(token);
  //       }
  //     } else {
  //       return error;
  //     }
  //   }));
  //   // __dio.options.baseUrl = baseUrl;
  //   return __dio;
  // }

  Future refrshToken() async {
    String rfreshToken =
        await ShPrefs.instance.getStringValue('refresh_access_token');
    String token = await ShPrefs.instance.getStringValue("access_token");
    String userName = await ShPrefs.instance.getStringValue('userName');
    var bodyJ = jsonEncode({
      "username": userName,
      "grant_type": "refresh_token",
      "refresh_token": rfreshToken,
    });
    // JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    // String prettyPrint = encoder.convert(bodyJ);
    // print(prettyPrint);

    Response response = await _dio.post(apiUrl + '/auth/tokens',
        data: {bodyJ},
        options: Options(headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }));

    if (response.statusCode == 200) {
      // print(response.body);
      // print(response.statusCode);
      Map<String, dynamic> res = jsonDecode(response.data);
      if (res['access_token'] != null) {
        await ShPrefs.instance
            .setStringValue('access_token', res['access_token']);
        return res['access_token'];
      }
    } else {
      if (response.statusCode == 401) {
        // print(response.body);
        // print(response.statusCode);
        //rout to login = log out
        logOut();
      } else {
        if (response.statusCode == 400) {
          // print(response.body);
          // print(response.statusCode);
          //400 (Bad Request ) Token verification failed.
          //if API not found
        } else {
          if (response.statusCode == 403) {
            // print(response.body);
            // print(response.statusCode);
            //403 (Forbidden)
          } else {
            // print("New error");
            // print(response.request.headers);
            // print(response.body);
            // print(response.statusCode);
          }
        }
      }
    }
    // deleteCacheDir();
  }

  Future logOut() async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await _dio.delete(apiUrl + '/auth/tokens',
          options: Options(headers: {
            "accept": "application/json",
            "Authorization": "Bearer $token",
          }));
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "تم تسجيل الخروج بنجاح شكراً لك ",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    } on DioError catch (e) {
      print(e.response.statusCode);
    }
    deleteCacheAndAppDir();
    ShPrefs.instance.removeAll();
  }

  Future<void> deleteCacheAndAppDir() async {
    final cacheDir = await getTemporaryDirectory();

    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
    final appDir = await getApplicationSupportDirectory();

    if (appDir.existsSync()) {
      appDir.deleteSync(recursive: true);
    }
  }

  checkIsSwitchedValue() async {
    String isSwitched = await ShPrefs.instance.getStringValue('isSwitched');
    print("isSwitched:" + await ShPrefs.instance.getStringValue('isSwitched'));
    if (isSwitched == 'false' || isSwitched == '') {
      logOut();
      ShPrefs.instance.removeValue('access_token');
      HomeScreen();
      return true;
    } else {
      return false;
    }
  }
}
