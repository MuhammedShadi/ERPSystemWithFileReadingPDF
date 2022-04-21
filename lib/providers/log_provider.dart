import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';

var apiUrl = "https://share.i.wdex.email/api/v1";

LoginProvider userAuth = new LoginProvider();
Dio dio;

class LogProvider {
  //
  Future<Map> viewLog() async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/log/?page=1&per_page=10',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      print(response.data);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data;
      }
    } on DioError catch (e) {
      print(e.response.data);
      print(e.response.statusCode);
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
    return null;
  }
}
