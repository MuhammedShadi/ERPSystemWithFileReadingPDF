import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdfviewer/models/new_user.dart';
import 'package:pdfviewer/models/user_item.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';

var apiUrl = "https://share.i.wdex.email/api/v1";

LoginProvider userAuth = new LoginProvider();
Dio dio;

class UsersProvider {
  Future<List<UserItem>> getAllActiveOrganizationUsers(String orgName) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/users/?active=true&page=1&per_page=50&organization=$orgName',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data['pages']);

      ShPrefs.instance
          .setStringValue('userPages', response.data['pages'].toString());
      List<UserItem> userItems = [];
      if (response.statusCode == 200) {
        for (var i in response.data["items"]) {
          UserItem userItem = new UserItem(
            i["_id"],
            i["name"],
            i["username"],
            i["email"],
            i["permissions"],
            i["organization"],
            i["account_type"],
            i["departments"],
            i["seen_at"],
            i["active"],
          );
          userItems.add(userItem);
        }
        return userItems;
      }
    } on DioError catch (e) {
      print(e.response.data);
      Fluttertoast.showToast(
        msg: "${e.response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print(e.response.statusCode);
      print("rrr");
    }
    return null;
  }

  Future<List<UserItem>> getOwnActiveOrganizationUsers() async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/users/?active=true&page=1&per_page=50',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data['pages']);
      ShPrefs.instance
          .setStringValue('userPages', response.data['pages'].toString());
      List<UserItem> userItems = [];
      if (response.statusCode == 200) {
        for (var i in response.data["items"]) {
          UserItem userItem = new UserItem(
            i["_id"],
            i["name"],
            i["username"],
            i["email"],
            i["permissions"],
            i["organization"],
            i["account_type"],
            i["departments"],
            i["seen_at"],
            i["active"],
          );
          userItems.add(userItem);
        }
        return userItems;
      }
    } on DioError catch (e) {
      // print(e.response.data);
      Fluttertoast.showToast(
        msg: "${e.response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // print(e.response.statusCode);
      // print("oooo");
    }
    return null;
  }

  Future<List<UserItem>> getUsersP({int pageNum = 1}) async {
    String departments = await ShPrefs.instance.getStringValue('department');
    String accountType = await ShPrefs.instance.getStringValue('accountTypes');
    String accountStatue =
        await ShPrefs.instance.getStringValue('accountStatues');
    String accountName = await ShPrefs.instance.getStringValue('names');
    String accountUserName = await ShPrefs.instance.getStringValue('usernames');
    String organization =
        await ShPrefs.instance.getStringValue('organizations');
    String filterParam = "";
    // print('test');
    if (departments != null) {
      filterParam += '$departments';
    }
    if (accountType != null) {
      filterParam += '$accountType';
    }
    if (accountStatue != null) {
      filterParam += '$accountStatue';
    }
    if (accountName != null && accountName.isNotEmpty) {
      filterParam += "&name=${Uri.encodeFull(accountName)}";
    }
    if (accountUserName != null && accountUserName.isNotEmpty) {
      filterParam += "&username=${Uri.encodeFull(accountUserName)}";
    }
    if (organization != null && organization.isNotEmpty) {
      filterParam += "&organization=${Uri.encodeFull(organization)}";
    }
    //print(filterParam);
    try {
      int maxPages = pageNum;

      String maxPageS = await ShPrefs.instance.getStringValue('usersPages');

      if (maxPageS != "") {
        maxPages = int.parse(maxPageS);
      }
      // print("maxP " + maxPages.toString());
      // print("pageNum " + pageNum.toString());
      if (pageNum <= maxPages) {
        Response response = await dio.get(
          apiUrl + '/users/?page=$pageNum&per_page=5$filterParam',
          options: Options(headers: {"accept": "application/json"}),
        );
        // print(apiUrl + '/users/?page=$pageNum&per_page=5$filterParam');
        ShPrefs.instance
            .setStringValue('usersPages', response.data['pages'].toString());

        List<UserItem> userItems = [];
        if (response.statusCode == 200) {
          for (var i in response.data["items"]) {
            UserItem userItem = new UserItem(
              i["_id"],
              i["name"],
              i["username"],
              i["email"],
              i["permissions"],
              i["organization"],
              i["account_type"],
              i["departments"],
              i["seen_at"],
              i['active'],
              i['hierarchy'],
            );
            // print(userItem.hierarchy);
            userItems.add(userItem);
          }
          return userItems;
        }
      }
    } on DioError catch (e) {
      if (e.response.statusCode == 404) {
      } else {
        // print(apiUrl + '/users/?page=$pageNum&per_page=5$filterParam');
        print(e.response.data);
        Fluttertoast.showToast(
          msg: "${e.response.statusMessage}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print(e.response.statusCode);
      }
    }
    return null;
  }

  createNewUser(NewUser _newUser) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    String dataJ = '';
    if (_newUser.accountType == 'organization') {
      dataJ = jsonEncode({
        "name": _newUser.name,
        "account_type": _newUser.accountType,
        "username": _newUser.username,
        "email": _newUser.email,
        "password": _newUser.password,
        "hierarchy": _newUser.hierarchy
      });
      //print(dataJ);
      //print(_newUser.hierarchy);
    } else if (_newUser.accountType == 'admin-user') {
      dataJ = jsonEncode({
        "name": _newUser.name,
        "account_type": 'admin-user',
        "username": _newUser.username,
        "email": _newUser.email,
        "password": _newUser.password,
        "departments": _newUser.departments
      });
      //print(dataJ);
    } else {
      dataJ = jsonEncode({
        "name": _newUser.name,
        "account_type": 'regular-user',
        "username": _newUser.username,
        "email": _newUser.email,
        "password": _newUser.password,
        "departments": _newUser.departments
      });
      //print(dataJ);
    }
    try {
      Response response = await dio.post(apiUrl + "/users/",
          data: dataJ,
          options: Options(
            headers: {
              "accept": "application/json",
              "Authorization": "Bearer $token",
            },
          ));
      //print(dataJ);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "تم إضافة مستخدم جديد  ${_newUser.name}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return true;
      }
    } on DioError catch (e) {
      if (e.response.statusCode == 403) {
        Fluttertoast.showToast(
          msg: "Weak password/Duplicate or invalid username or email",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else if (e.response.statusCode == 400) {
        Fluttertoast.showToast(
          msg: 'Insufficient privileges',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print(e.response.statusCode);
        print(e.response.data);
      } else {
        Fluttertoast.showToast(
          msg: e.response.statusMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print(e.response.data);
        print(e.response.statusCode);
        print(e.response.isRedirect);
      }
    }
  }

  updateUserDetails(String accountType, String userName, String name,
      String email, List departments, List hierarchy) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    String dataJ = '';
    if (accountType == '') {
      dataJ = jsonEncode({
        "name": name,
        "email": email,
        "hierarchy": hierarchy,
      });
    } else {
      dataJ = dataJ = jsonEncode({
        "name": name,
        "email": email,
        "departments": departments,
      });
    }
    try {
      Response response = await dio.put(
        apiUrl + '/users/$userName',
        data: dataJ,
        options: Options(headers: {
          "Content-Type": "application/json",
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data);
      // print(apiUrl + '/users/$userName');
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "$userName تم تحديث بيانات ",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return true;
      }
    } on DioError catch (e) {
      print(e.response.statusCode);
      print(e.response.data);
      if (e.response.statusCode == 403) {
        Fluttertoast.showToast(
          msg: "Organization account departments can not be modified",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
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
    }
  }

  Future<Map> getUserDetails(String userName) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/users/$userName',
        options: Options(headers: {
          "accept": "application/json",
          // "X-Fields": "{departments}",
          "Authorization": "Bearer $token",
        }),
      );
      //  print(response.data);
      if (response.statusCode == 200) {
        // print(response.data);
        return response.data;
      }
    } on DioError catch (e) {
      print(e.response.statusCode);
      print(e.response.data);
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

  Future<List<String>> getOrganizationDepartments(String userName) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/users/$userName',
        options: Options(headers: {
          "accept": "application/json",
          "X-Fields": "{departments}",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data);
      if (response.statusCode == 200) {
        List<String> deps = [];
        if (response.data["departments"] != null) {
          for (var d in response.data["departments"]) {
            deps.add(d.toString());
          }
          return deps;
        }
      }
    } on DioError catch (e) {
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

  deActiveAccount(String userName) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.delete(
        apiUrl + '/users/$userName',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "تم تعطيل الحساب بنجاح  $userName",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return true;
      }
    } on DioError catch (e) {
      print(apiUrl + '/users/$userName');
      print(e.response.statusCode);
      if (e.response.statusCode == 401) {
        userAuth.refrshToken();
        Fluttertoast.showToast(
          msg: e.response.statusMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else if (e.response.statusCode == 403) {
        userAuth.refrshToken();
        Fluttertoast.showToast(
          msg: 'لا يمكن تعطيل هذا الحساب',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: e.response.statusMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      // print(e.response.data);
      // print(e.response.statusCode);
    }
  }

  Future<Map> reActiveAccount(String userName) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.post(
        apiUrl + '/users/$userName',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data);
      if (response.statusCode == 200 || response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "تم تفعيل الحساب بنجاح  $userName",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      return response.data;
    } on DioError catch (e) {
      print(apiUrl + '/users/$userName');
      print(e.response.statusCode);
      if (e.response.statusCode == 401) {
        userAuth.refrshToken();
        Fluttertoast.showToast(
          msg: e.response.statusMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: e.response.statusMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      // print(e.response.data);
      // print(e.response.statusCode);
    }
    return null;
  }

  updateUserPassword(String userName, String newPassword,
      {String oldPassword}) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    var data;
    if (oldPassword != null) {
      data = jsonEncode({
        "old_password": oldPassword,
        "new_password": newPassword,
      });
    } else {
      data = jsonEncode({
        "new_password": newPassword,
      });
    }
    try {
      Response response = await dio.put(
        apiUrl + '/users/$userName/password',
        data: data,
        options: Options(headers: {
          "Content-Type": "application/json",
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data);
      // print(apiUrl + '/users/$userName');
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "$userName تم تحديث بيانات ",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return true;
      }
    } on DioError catch (e) {
      print(e.response.statusCode);
      print(e.response.data);
      if (e.response.statusCode == 403) {
        Fluttertoast.showToast(
          msg: "A user can only change his own password",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
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
    }
  }
}
